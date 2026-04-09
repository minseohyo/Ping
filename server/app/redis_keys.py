from __future__ import annotations


def user_key(user_id: str) -> str:
    return f"user:{user_id}"


def device_key(device_id: str) -> str:
    return f"device:{device_id}"


def matching_queue_key(region_id: str) -> str:
    return f"matching:queue:{region_id}"


def room_members_key(room_id: str) -> str:
    return f"room:{room_id}:members"


def user_room_key(user_id: str) -> str:
    return f"user:{user_id}:roomId"

