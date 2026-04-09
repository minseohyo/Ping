from __future__ import annotations

import json
import uuid
from typing import Any, Optional

import redis.asyncio as redis

from . import redis_keys as keys


class RedisStore:
    def __init__(self, client: redis.Redis):
        self.r = client

    async def upsert_user_by_device(self, device_id: str, nickname: str) -> dict[str, Any]:
        existing_user_id = await self.r.get(keys.device_key(device_id))
        if existing_user_id:
            user_id = existing_user_id.decode("utf-8")
        else:
            user_id = f"u_{uuid.uuid4().hex[:12]}"
            await self.r.set(keys.device_key(device_id), user_id)

        user = {"userId": user_id, "deviceId": device_id, "nickname": nickname, "avatarUrl": None}
        await self.r.set(keys.user_key(user_id), json.dumps(user))
        return user

    async def get_user_id_by_device(self, device_id: str) -> Optional[str]:
        v = await self.r.get(keys.device_key(device_id))
        return v.decode("utf-8") if v else None

    async def get_user(self, user_id: str) -> Optional[dict[str, Any]]:
        v = await self.r.get(keys.user_key(user_id))
        return json.loads(v) if v else None

    async def get_user_by_device(self, device_id: str) -> Optional[dict[str, Any]]:
        user_id = await self.get_user_id_by_device(device_id)
        if not user_id:
            return None
        return await self.get_user(user_id)

    async def get_fixed_room_id(self, user_id: str) -> Optional[str]:
        v = await self.r.get(keys.user_room_key(user_id))
        return v.decode("utf-8") if v else None

    async def set_fixed_room_id(self, user_id: str, room_id: str) -> None:
        await self.r.set(keys.user_room_key(user_id), room_id)

    async def clear_fixed_room_id(self, user_id: str) -> None:
        await self.r.delete(keys.user_room_key(user_id))

    async def room_add_member(self, room_id: str, user_id: str) -> None:
        await self.r.sadd(keys.room_members_key(room_id), user_id)

    async def room_remove_member(self, room_id: str, user_id: str) -> None:
        await self.r.srem(keys.room_members_key(room_id), user_id)

    async def room_get_members(self, room_id: str) -> list[str]:
        members = await self.r.smembers(keys.room_members_key(room_id))
        return [m.decode("utf-8") for m in members]

    async def room_delete_if_empty(self, room_id: str) -> None:
        count = await self.r.scard(keys.room_members_key(room_id))
        if count == 0:
            await self.r.delete(keys.room_members_key(room_id))

    async def matching_enqueue(self, region_id: str, user_id: str) -> None:
        # Avoid duplicates by removing existing occurrences, then push to tail.
        q = keys.matching_queue_key(region_id)
        await self.r.lrem(q, 0, user_id)
        await self.r.rpush(q, user_id)

    async def matching_pop_group(self, region_id: str, max_size: int) -> list[str]:
        q = keys.matching_queue_key(region_id)
        # Non-atomic but OK for MVP local; can be improved with Lua/transactions later.
        size = await self.r.llen(q)
        if size < 2:
            return []
        take = min(int(size), max_size)
        out: list[str] = []
        for _ in range(take):
            v = await self.r.lpop(q)
            if not v:
                break
            out.append(v.decode("utf-8"))
        return out

