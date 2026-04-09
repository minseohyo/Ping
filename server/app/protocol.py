from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Literal, Optional

from pydantic import BaseModel, Field


def now_iso_utc() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


class Envelope(BaseModel):
    type: str
    version: int = 1
    payload: dict[str, Any] = Field(default_factory=dict)


class Member(BaseModel):
    userId: str
    nickname: str
    avatarUrl: Optional[str] = None


class RegisterRequest(BaseModel):
    deviceId: str
    nickname: str


class RegisterResponse(BaseModel):
    userId: str
    deviceId: str
    nickname: str


class MeResponse(BaseModel):
    userId: str
    deviceId: str
    nickname: str


class MatchingStartRequest(BaseModel):
    deviceId: str
    regionId: str = "default"


class LeaveRoomRequest(BaseModel):
    deviceId: str


# Command payloads (WS)
class StartMatchingPayload(BaseModel):
    deviceId: str
    regionId: str = "default"


class JoinRoomPayload(BaseModel):
    deviceId: str
    roomId: str


class SendEmojiPayload(BaseModel):
    deviceId: str
    toUserId: str
    emojiId: str


# Event payloads (WS)
class MatchedPayload(BaseModel):
    roomId: str
    members: list[Member]


class RoomStateUpdatedPayload(BaseModel):
    roomId: str
    members: list[Member]


class EmojiReceivedPayload(BaseModel):
    roomId: str
    from_: str = Field(alias="from")
    to: str
    emojiId: str
    timestamp: str

    class Config:
        populate_by_name = True


class ErrorPayload(BaseModel):
    code: str
    message: str
    recoverable: bool = True


CommandType = Literal["startMatching", "joinRoom", "sendEmoji"]
EventType = Literal["matched", "roomStateUpdated", "emojiReceived", "error"]

