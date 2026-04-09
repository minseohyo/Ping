from __future__ import annotations

import os

from pydantic import BaseModel


class Settings(BaseModel):
    redis_url: str = os.getenv("REDIS_URL", "redis://localhost:6379/0")
    ws_path: str = os.getenv("WS_PATH", "/ws")


settings = Settings()

