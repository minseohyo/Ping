# Ping MVP Server (FastAPI + WebSocket + Redis)

## Requirements

- Python 3.11+ (3.10도 대체로 동작)
- Docker Desktop (Redis 실행용, 권장)

## Quick start (Redis: Docker)

```bash
cd server
docker compose up -d redis
python -m venv .venv
.\.venv\Scripts\activate
python -m pip install -r requirements.txt
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

서버가 뜨면:
- REST: `http://localhost:8000`
- WS: `ws://localhost:8000/ws`

## REST endpoints (MVP)

- `POST /auth/register` : deviceId + nickname upsert → userId 반환
- `GET /me?deviceId=...` : deviceId로 내 프로필 조회
- `POST /matching/start` : 매칭 시작(매칭 결과는 WS 이벤트로 push)
- `POST /room/leave` : room 고정 해제

## WebSocket protocol

WS 메시지는 공통 Envelope `{type, version, payload}`를 사용합니다. 상세 스펙은
`../docs/protocol.md` 참고.

## Redis keys (MVP)

- `user:{userId}` → JSON (profile)
- `device:{deviceId}` → userId (string)
- `matching:queue:{regionId}` → LIST of userId
- `room:{roomId}:members` → SET of userId
- `user:{userId}:roomId` → roomId (string)

## Notes (MVP matching rule)

MVP에서는 비용/복잡도를 줄이기 위해, `startMatching`이 들어올 때
해당 `regionId` 큐에서 **최소 2명 이상**이면 즉시 room을 만들어 매칭합니다.
최대 10명까지 한 room에 넣습니다.

## Moving to a VPS later (3 lines)

1) `REDIS_URL`을 VPS의 Redis 주소로 변경  
2) `uvicorn`을 `--host 0.0.0.0`로 실행하고 방화벽/포트를 오픈  
3) 실제 도메인/HTTPS가 필요해지면 Nginx/Caddy로 리버스 프록시 구성

