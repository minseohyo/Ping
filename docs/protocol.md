# Ping MVP Protocol (v1)

이 문서는 **Ping MVP의 iOS/Android 공통** 서버-클라이언트 통신 규격을 정의합니다.
MVP 목표는 “클라이언트는 UI + 이벤트 전달”, “비즈니스 로직은 서버” 원칙을 유지하는 것입니다.

## Goals / Non-goals

- **Goals**
  - iOS/Android가 **동일한 JSON 스키마**(type/version/payload)로 REST/WS를 사용
  - Command/Event 확장(하트, 투표 등)이 **구조 변경 없이 type 추가**로 가능
  - MVP에서 “근처”는 `regionId`로 단순화 (기본 `"default"`)
- **Non-goals (MVP)**
  - 영속 저장(재시작 시 데이터 유지) 보장
  - 정교한 지리 기반 근접 매칭(GPS 스트리밍, 지오쿼리)

---

## 1) Common Envelope (모든 메시지 공통 포맷)

모든 WebSocket 메시지(클라→서버 Command, 서버→클라 Event)는 아래 Envelope를 사용합니다.

```json
{
  "type": "string",
  "version": 1,
  "payload": {}
}
```

- **type**
  - `lowerCamelCase` 권장
  - Command와 Event는 같은 공간에서 유니크해야 함 (예: `sendEmoji`, `emojiReceived`)
- **version**
  - MVP에서는 `1` 고정
  - **Breaking change**가 필요한 경우 `2`로 올리고, 서버는 일정 기간 `v1/v2` 동시 지원 권장
- **payload**
  - type별 실제 데이터

### Identifiers & Time

- **deviceId**: 클라이언트가 생성/저장(Keychain 등)하는 안정 식별자 (UUID 문자열 권장)
- **userId**: 서버가 발급하는 유저 식별자 (문자열)
- **roomId**: 서버가 발급하는 룸 식별자 (문자열)
- **timestamp**: ISO-8601 UTC 문자열 권장 (예: `"2026-04-09T12:34:56.789Z"`)

---

## 2) Core Models (공통 데이터 모델)

### Member (Room 내 표시용)

```json
{
  "userId": "u_123",
  "nickname": "seohy",
  "avatarUrl": null
}
```

- `avatarUrl`: MVP에서는 `null` 허용 (추후 프로필 확장 시 사용)

---

## 3) WebSocket Commands (Client → Server)

> WebSocket 연결은 “실시간 이벤트 수신/상호작용”에 사용합니다.  
> MVP에서는 **WS 하나만으로도 매칭→룸→이모티콘**을 전부 처리할 수 있게 설계합니다.

### 3.1 `startMatching`

```json
{
  "type": "startMatching",
  "version": 1,
  "payload": {
    "deviceId": "b2d3d0b6-9d9f-4c8e-9c5a-1d2c9b4a6c10",
    "regionId": "default"
  }
}
```

- 서버는 아래 중 하나를 수행:
  - (A) 이미 `roomId`가 고정된 유저라면 `matched`를 즉시 재전송
  - (B) 매칭 큐에 넣고, 매칭 성사 시 `matched` 발행

### 3.2 `joinRoom`

```json
{
  "type": "joinRoom",
  "version": 1,
  "payload": {
    "deviceId": "b2d3d0b6-9d9f-4c8e-9c5a-1d2c9b4a6c10",
    "roomId": "r_abcd"
  }
}
```

- 서버는 성공 시 **즉시** `roomStateUpdated`를 보냅니다.

### 3.3 `sendEmoji`

```json
{
  "type": "sendEmoji",
  "version": 1,
  "payload": {
    "deviceId": "b2d3d0b6-9d9f-4c8e-9c5a-1d2c9b4a6c10",
    "toUserId": "u_456",
    "emojiId": "thumbs_up"
  }
}
```

- 서버는 검증 후 같은 room에 `emojiReceived`를 브로드캐스트합니다.

---

## 4) WebSocket Events (Server → Client)

### 4.1 `matched`

```json
{
  "type": "matched",
  "version": 1,
  "payload": {
    "roomId": "r_abcd",
    "members": [
      { "userId": "u_123", "nickname": "seohy", "avatarUrl": null },
      { "userId": "u_456", "nickname": "min", "avatarUrl": null }
    ]
  }
}
```

의미:
- 매칭이 성사되었고, 유저는 해당 `roomId`에 **고정**됩니다.
- 클라이언트는 `RoomFeature`로 라우팅한 뒤, 안전하게 `joinRoom`을 한 번 더 보내도 됩니다(멱등 권장).

### 4.2 `roomStateUpdated`

```json
{
  "type": "roomStateUpdated",
  "version": 1,
  "payload": {
    "roomId": "r_abcd",
    "members": [
      { "userId": "u_123", "nickname": "seohy", "avatarUrl": null },
      { "userId": "u_456", "nickname": "min", "avatarUrl": null }
    ]
  }
}
```

의미:
- 현재 room의 멤버 스냅샷입니다.
- MVP에서는 diff가 아니라 **full snapshot**으로 단순화합니다.

### 4.3 `emojiReceived`

```json
{
  "type": "emojiReceived",
  "version": 1,
  "payload": {
    "roomId": "r_abcd",
    "from": "u_123",
    "to": "u_456",
    "emojiId": "thumbs_up",
    "timestamp": "2026-04-09T12:34:56.789Z"
  }
}
```

의미:
- 룸 내 상호작용 이벤트입니다.
- 수신 클라이언트는 `to` 유저 아바타 위에 이모티콘을 잠깐 표시합니다.

---

## 5) Errors (MVP 최소 규약)

MVP에서는 아래 에러 이벤트만 표준으로 둡니다.

### `error`

```json
{
  "type": "error",
  "version": 1,
  "payload": {
    "code": "string",
    "message": "string",
    "recoverable": true
  }
}
```

권장 code 예시:
- `unauthorized_device`
- `room_not_found`
- `room_full`
- `user_not_in_room`
- `invalid_payload`

---

## 6) REST vs WebSocket 역할 분리 (MVP)

| 영역 | REST(HTTP) | WebSocket |
|---|---|---|
| 인증/등록 | deviceId+nickname 등록, 프로필 조회 | (선택) 연결 시 deviceId 전달만 |
| 매칭 시작 | 가능(단순) | **권장**: `startMatching` 커맨드 |
| 룸 상태 | 초기 진입 시 조회(선택) | **권장**: `roomStateUpdated` push |
| 상호작용 | 비권장(지연/폴링) | **권장**: `sendEmoji` → `emojiReceived` |

MVP 권장 운영:
- REST는 “초기 상태/등록” 용도에 집중
- 실시간 흐름(매칭/룸/이모지)은 WS로 통일

---

## 7) End-to-end Data Flow (Matching → Room → Interaction)

### 7.1 최초 실행 / 로그인(등록)
1. 클라이언트는 `deviceId`를 생성하여 로컬(Keychain)에 저장
2. REST로 닉네임 등록/조회 후 `userId` 확보

### 7.2 Ping 매칭
1. 클라이언트가 WS 연결
2. 클라이언트 → 서버: `startMatching(deviceId, regionId="default")`
3. 서버가 매칭 성사 시 서버 → 클라이언트: `matched(roomId, members)`
4. 클라이언트는 UI 라우팅(매칭 화면 → 룸 화면)

### 7.3 Room 입장 및 상태 동기화
1. 클라이언트 → 서버: `joinRoom(deviceId, roomId)`
2. 서버 → 클라이언트: `roomStateUpdated(roomId, members)` (즉시 1회 + 변경 시마다)

### 7.4 이모티콘 상호작용
1. 클라이언트 → 서버: `sendEmoji(deviceId, toUserId, emojiId)`
2. 서버 → (room 멤버 전체) `emojiReceived(from, to, emojiId, timestamp)`
3. 클라이언트는 `to` 유저 위에 애니메이션 표시

---

## 8) Collaboration / GitHub 운영 가이드(권장)

프로토콜 변경은 클라(iOS/Android)와 서버가 동시에 영향을 받으므로, 아래 원칙을 권장합니다.

- **Single source of truth**: 이 문서(`docs/protocol.md`)가 1순위
- **변경 규칙**
  - (1) type 추가: **호환성 유지** → version 그대로(=1) 가능
  - (2) payload 필드 추가: 기본값/nullable로 **하위 호환** 유지
  - (3) 필드 제거/의미 변경: **Breaking** → version 증가 고려(=2)
- **PR 체크리스트(권장)**
  - 문서에 JSON 예시 추가/수정
  - 서버/클라 각각 해당 type 처리 추가

