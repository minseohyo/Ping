# Xcode 14.2 + macOS Monterey — 완전 초보용 실행 가이드

이 레포의 iOS 코드는 **Xcode 14.2 / iOS 16+ / Swift 5.7** 기준으로 맞춰져 있습니다.

---

## 1. 새 SwiftUI 프로젝트 만들기

1. **Xcode** 실행
2. 메뉴 **File → New → Project…**
3. **iOS** 탭 → **App** 선택 → **Next**
4. 옵션 입력:
   - **Product Name**: 예) `PingApp`
   - **Team**: (실기기 배포 시 선택, 시뮬만이면 나중에 가능)
   - **Organization Identifier**: 예) `com.minseohyo`
   - **Interface**: **SwiftUI**
   - **Language**: **Swift**
   - **Storage**: None
5. 저장 위치: 이 Git 레포 안 아무 폴더(예: `Ping/ios/PingAppXcode/`) → **Create**

---

## 2. Deployment Target을 iOS 16으로

1. 왼쪽 **프로젝트(파란 아이콘)** 클릭
2. **TARGETS**에서 앱 타깃 선택
3. **General** 탭 → **Minimum Deployments** → **iOS 16.0** (또는 16.x)

---

## 3. Local Package 연결 (`ios/Packages`)

각 패키지는 **폴더마다 `Package.swift`가 있는 단위**로 추가합니다.

1. 프로젝트 네비게이터에서 **프로젝트(맨 위)** 선택
2. **Package Dependencies** 탭
3. 왼쪽 하단 **+**
4. **Add Local…** 선택
5. Finder에서 레포의 `Ping/ios/Packages/CoreModels` 폴더 선택 → **Add Package**
6. “Choose Package Products for PingApp” 화면에서 **CoreModels**를 앱 타깃에 **Add** (또는 Finish)

아래 폴더를 **같은 방식으로 반복** 추가합니다.

- `CoreNetworking`
- `CorePersistence`
- `CoreDI`
- `CoreUI`
- `AuthFeature`
- `MatchingFeature`
- `RoomFeature`
- `InteractionFeature`
- `ProfileFeature` (지금은 비어 있어도 추가해 두면 됨)

7. **TARGETS → 앱 타깃 → General → Frameworks, Libraries, and Embedded Content**  
   위 패키지들이 **모두 링크**되어 있는지 확인합니다. 없으면 **+** 로 추가합니다.

---

## 4. Composition Root 파일 넣기 + @main 연결

레포에 있는 스켈레톤을 Xcode 프로젝트에 넣습니다.

1. Finder에서 다음 두 파일을 확인:
   - `ios/PingAppSkeleton/PingAppEntry.swift`  ← **@main** (앱 진입점)
   - `ios/PingAppSkeleton/PingApp.swift`        ← `PingAppRootView`, 라우터

2. Xcode 왼쪽에서 앱 그룹 우클릭 → **Add Files to "PingApp"…**
3. 위 두 파일 선택
4. 옵션:
   - **Copy items if needed**: 체크 권장(레포 밖으로 복사할 때)
   - **Add to targets**: 앱 타깃 체크
5. **Add**

6. Xcode가 자동으로 만든 `PingAppApp.swift`(또는 `*App.swift`)를 연다.
7. 그 파일 안의 **`@main`** 이 **`PingAppEntry.swift`의 `PingApplication`과 중복**되면 빌드 오류가 납니다.
   - **방법 A(권장)**: `PingAppApp.swift` 파일 전체를 삭제하거나, `@main` 한 줄만 제거하고 빈 `struct`는 남기지 말고 파일 삭제가 깔끔합니다.

최종적으로 **`@main`은 `PingApplication` 하나만** 남아 있어야 합니다.

---

## 5. `API_BASE_URL`, `WS_BASE_URL` (Info.plist)

### Xcode 13+ (Info 탭)

1. **TARGETS → 앱 타깃 → Info** 탭
2. **Custom iOS Target Properties** 표에서 **+** 로 행 추가
3. Key에 다음을 입력 (직접 타이핑):

| Key | Type | Value |
|-----|------|--------|
| `API_BASE_URL` | String | `http://127.0.0.1:8000` |
| `WS_BASE_URL` | String | `ws://127.0.0.1:8000/ws` |

- 시뮬레이터에서 맥에 뜬 서버에 붙을 때는 **`127.0.0.1`** 이 가장 무난합니다.
- 실제 아이폰(USB)에서 **같은 Wi‑Fi의 맥 IP**로 바꿉니다. 예: `http://192.168.0.12:8000`, `ws://192.168.0.12:8000/ws`

코드는 `AppContainer.makeFromInfoPlist()`에서 위 키를 읽습니다. (`CoreDI`)

---

## 6. 서버 실행 (맥 터미널)

레포의 `server/README.md` 참고. 예:

```bash
cd server
docker compose up -d redis
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

---

## 7. 시뮬레이터에서 실행

1. Xcode 상단 스킴 옆 기기 메뉴에서 **iPhone 시뮬레이터** 선택
2. **▶ Run**
3. 앱에서 닉네임 등록 → Ping → (서버에 유저 2명 이상이면) 매칭 후 Room 화면으로 이동

---

## 8. 실제 iPhone에서 실행

1. 아이폰 **설정 → 개인정보 보호 및 보안 → 개발자 모드** (iOS 16+에서 필요할 수 있음)
2. USB 연결
3. Xcode 상단에서 **iPhone 기기** 선택
4. **TARGETS → Signing & Capabilities** 에서 **Team** 선택 (Apple ID)
5. **▶ Run**  
   첫 실행 시 아이폰에서 **신뢰** 안내가 뜨면 설정에서 개발자 앱 신뢰

**Info.plist의 URL**을 반드시 맥의 LAN IP로 바꿉니다 (`127.0.0.1`은 폰 자기 자신을 가리킵니다).

---

## 문제가 자주 나는 것

- **“No such module CoreModels”**: Package Dependencies / 링크 단계 누락 → 3번 다시 확인
- **`@main` 중복**: `PingAppApp.swift` 삭제 또는 `@main` 제거
- **WebSocket 연결 실패**: 서버가 `0.0.0.0:8000`으로 떠 있는지, 방화벽, URL이 `ws://` 인지 확인
