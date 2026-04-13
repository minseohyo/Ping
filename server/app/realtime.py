from __future__ import annotations

import asyncio
from dataclasses import dataclass
from typing import Optional

from fastapi import WebSocket


@dataclass
class Connection:
    user_id: str
    websocket: WebSocket
    room_id: Optional[str] = None
    lock: asyncio.Lock = None  # assigned per-connection


class RealtimeHub:
    def __init__(self) -> None:
        self._by_user: dict[str, Connection] = {}

    def get(self, user_id: str) -> Optional[Connection]:
        return self._by_user.get(user_id)

    async def connect(self, user_id: str, websocket: WebSocket) -> Connection:
        conn = Connection(user_id=user_id, websocket=websocket, room_id=None, lock=asyncio.Lock())
        self._by_user[user_id] = conn
        return conn

    def disconnect(self, user_id: str) -> None:
        self._by_user.pop(user_id, None)

    def set_room(self, user_id: str, room_id: Optional[str]) -> None:
        conn = self._by_user.get(user_id)
        if conn:
            conn.room_id = room_id

    async def send_to_user(self, user_id: str, message: dict) -> None:
        conn = self._by_user.get(user_id)
        if not conn:
            return
        async with conn.lock:
            await conn.websocket.send_json(message)

    async def broadcast_to_room(self, room_id: str, user_ids: list[str], message: dict) -> None:
        # user_ids is authoritative from Redis (MVP).
        for uid in user_ids:
            await self.send_to_user(uid, message)

