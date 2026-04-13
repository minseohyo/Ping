from __future__ import annotations

import uuid
from typing import Any, Optional

import redis.asyncio as redis
from fastapi import FastAPI, HTTPException, Query, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware

from .config import settings
from .protocol import (
    Envelope,
    ErrorPayload,
    JoinRoomPayload,
    MatchingStartRequest,
    MatchedPayload,
    LeaveRoomRequest,
    MeResponse,
    Member,
    RegisterRequest,
    RegisterResponse,
    RoomStateUpdatedPayload,
    SendEmojiPayload,
    StartMatchingPayload,
    now_iso_utc,
)
from .realtime import RealtimeHub
from .store import RedisStore


app = FastAPI(title="Ping MVP Server", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


hub = RealtimeHub()


def env(type_: str, payload: dict[str, Any]) -> dict[str, Any]:
    return {"type": type_, "version": 1, "payload": payload}


async def get_store() -> RedisStore:
    # Simple global client for MVP.
    if not hasattr(app.state, "redis"):
        app.state.redis = redis.from_url(settings.redis_url, decode_responses=False)
        app.state.store = RedisStore(app.state.redis)
    return app.state.store


async def require_user_id(store: RedisStore, device_id: str) -> str:
    user_id = await store.get_user_id_by_device(device_id)
    if not user_id:
        raise HTTPException(status_code=401, detail="Unknown deviceId. Register first.")
    return user_id


async def members_for_room(store: RedisStore, room_id: str) -> list[Member]:
    user_ids = await store.room_get_members(room_id)
    members: list[Member] = []
    for uid in user_ids:
        u = await store.get_user(uid)
        if not u:
            continue
        members.append(Member(userId=u["userId"], nickname=u["nickname"], avatarUrl=u.get("avatarUrl")))
    # Stable-ish ordering for UI (nickname then userId)
    members.sort(key=lambda m: (m.nickname, m.userId))
    return members


async def push_room_state(store: RedisStore, room_id: str) -> None:
    members = await members_for_room(store, room_id)
    user_ids = [m.userId for m in members]
    await hub.broadcast_to_room(
        room_id,
        user_ids=user_ids,
        message=env("roomStateUpdated", RoomStateUpdatedPayload(roomId=room_id, members=members).model_dump()),
    )


async def ensure_room_membership(store: RedisStore, user_id: str, room_id: str) -> None:
    await store.set_fixed_room_id(user_id, room_id)
    await store.room_add_member(room_id, user_id)


async def do_match_if_possible(store: RedisStore, region_id: str) -> Optional[tuple[str, list[str]]]:
    group = await store.matching_pop_group(region_id, max_size=10)
    if not group:
        return None
    room_id = f"r_{uuid.uuid4().hex[:8]}"
    for uid in group:
        await ensure_room_membership(store, uid, room_id)
    return room_id, group


async def emit_matched(store: RedisStore, room_id: str, user_ids: list[str]) -> None:
    members = await members_for_room(store, room_id)
    payload = MatchedPayload(roomId=room_id, members=members).model_dump()
    for uid in user_ids:
        await hub.send_to_user(uid, env("matched", payload))
    await push_room_state(store, room_id)


# --------------------
# REST
# --------------------


@app.post("/auth/register", response_model=RegisterResponse)
async def register(body: RegisterRequest) -> RegisterResponse:
    store = await get_store()
    user = await store.upsert_user_by_device(body.deviceId, body.nickname)
    return RegisterResponse(userId=user["userId"], deviceId=body.deviceId, nickname=user["nickname"])


@app.get("/me", response_model=MeResponse)
async def me(deviceId: str = Query(...)) -> MeResponse:
    store = await get_store()
    user = await store.get_user_by_device(deviceId)
    if not user:
        raise HTTPException(status_code=401, detail="Unknown deviceId. Register first.")
    return MeResponse(userId=user["userId"], deviceId=deviceId, nickname=user["nickname"])


@app.post("/matching/start")
async def matching_start(body: MatchingStartRequest) -> dict[str, Any]:
    """
    MVP: REST로 매칭을 시작할 수 있게 제공하되,
    매칭 결과(matched)는 WebSocket 이벤트로 push됩니다.
    """
    store = await get_store()
    user_id = await require_user_id(store, body.deviceId)

    fixed = await store.get_fixed_room_id(user_id)
    if fixed:
        members = await members_for_room(store, fixed)
        return {"status": "already_matched", "roomId": fixed, "members": [m.model_dump() for m in members]}

    await store.matching_enqueue(body.regionId, user_id)
    matched = await do_match_if_possible(store, body.regionId)
    if matched:
        room_id, user_ids = matched
        await emit_matched(store, room_id, user_ids)
        return {"status": "matched", "roomId": room_id}

    return {"status": "queued"}


@app.post("/room/leave")
async def room_leave(body: LeaveRoomRequest) -> dict[str, Any]:
    store = await get_store()
    user_id = await require_user_id(store, body.deviceId)

    room_id = await store.get_fixed_room_id(user_id)
    if not room_id:
        return {"status": "ok", "left": False}

    await store.room_remove_member(room_id, user_id)
    await store.clear_fixed_room_id(user_id)
    await store.room_delete_if_empty(room_id)
    await push_room_state(store, room_id)
    hub.set_room(user_id, None)
    return {"status": "ok", "left": True}


# --------------------
# WebSocket
# --------------------


@app.websocket(settings.ws_path)
async def ws_endpoint(websocket: WebSocket) -> None:
    """
    MVP WS:
    - connect 후 client가 {type,version,payload} command를 보냄
    - deviceId 기반으로 user를 식별
    """
    store = await get_store()
    user_id: Optional[str] = None

    # Handshake must be accepted before receiving frames.
    await websocket.accept()

    try:
        # First message must include deviceId in payload (any command is OK).
        first_raw = await websocket.receive_json()
        first = Envelope.model_validate(first_raw)
        device_id = first.payload.get("deviceId")
        if not device_id:
            await websocket.send_json(env("error", ErrorPayload(code="unauthorized_device", message="deviceId required").model_dump()))
            await websocket.close(code=1008)
            return

        user_id = await store.get_user_id_by_device(device_id)
        if not user_id:
            await websocket.send_json(env("error", ErrorPayload(code="unauthorized_device", message="Unknown deviceId").model_dump()))
            await websocket.close(code=1008)
            return

        conn = await hub.connect(user_id, websocket)

        # Process the first message as normal.
        await handle_ws_message(store, conn.user_id, first)

        while True:
            raw = await websocket.receive_json()
            msg = Envelope.model_validate(raw)
            await handle_ws_message(store, conn.user_id, msg)

    except WebSocketDisconnect:
        if user_id:
            hub.disconnect(user_id)
    except Exception as e:
        # Best-effort error message
        print("WS ERROR:", repr(e))
        try:
            await websocket.send_json(env("error", ErrorPayload(code="server_error", message=str(e)).model_dump()))
        except Exception:
            pass
        try:
            await websocket.close(code=1011)
        except Exception:
            pass
        if user_id:
            hub.disconnect(user_id)


async def handle_ws_message(store: RedisStore, user_id: str, msg: Envelope) -> None:
    t = msg.type

    # If user already has fixed room, we can proactively re-emit matched on startMatching.
    if t == "startMatching":
        payload = StartMatchingPayload.model_validate(msg.payload)
        fixed = await store.get_fixed_room_id(user_id)
        if fixed:
            hub.set_room(user_id, fixed)
            members = await members_for_room(store, fixed)
            await hub.send_to_user(user_id, env("matched", MatchedPayload(roomId=fixed, members=members).model_dump()))
            await push_room_state(store, fixed)
            return

        await store.matching_enqueue(payload.regionId, user_id)
        matched = await do_match_if_possible(store, payload.regionId)
        if matched:
            room_id, user_ids = matched
            for uid in user_ids:
                hub.set_room(uid, room_id)
            await emit_matched(store, room_id, user_ids)
        return

    if t == "joinRoom":
        payload = JoinRoomPayload.model_validate(msg.payload)
        fixed = await store.get_fixed_room_id(user_id)
        if fixed and fixed != payload.roomId:
            await hub.send_to_user(
                user_id,
                env("error", ErrorPayload(code="room_mismatch", message="User is fixed to a different room").model_dump()),
            )
            return

        # If not fixed yet (e.g., reconnect), allow join to re-fix.
        await ensure_room_membership(store, user_id, payload.roomId)
        hub.set_room(user_id, payload.roomId)
        await push_room_state(store, payload.roomId)
        return

    if t == "sendEmoji":
        payload = SendEmojiPayload.model_validate(msg.payload)
        room_id = await store.get_fixed_room_id(user_id)
        if not room_id:
            await hub.send_to_user(
                user_id,
                env("error", ErrorPayload(code="user_not_in_room", message="User is not in a room").model_dump()),
            )
            return

        # Validate target membership (MVP: same room)
        member_ids = await store.room_get_members(room_id)
        if payload.toUserId not in member_ids:
            await hub.send_to_user(
                user_id,
                env("error", ErrorPayload(code="user_not_in_room", message="Target not in same room").model_dump()),
            )
            return

        event_payload = {
            "roomId": room_id,
            "from": user_id,
            "to": payload.toUserId,
            "emojiId": payload.emojiId,
            "timestamp": now_iso_utc(),
        }
        await hub.broadcast_to_room(room_id, user_ids=member_ids, message=env("emojiReceived", event_payload))
        return

    await hub.send_to_user(
        user_id,
        env("error", ErrorPayload(code="unknown_type", message=f"Unknown type: {t}").model_dump()),
    )

