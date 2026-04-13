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
3. 왼쪽 하단 **+** 를 누르면 **위쪽에 URL 입력창만** 보이는 창이 뜹니다. **그 창의 왼쪽 아래**(또는 하단)에 **`Add Local…`** / **`Add Local Package…`** 버튼이 있습니다. 그걸 누릅니다.  
   - 안 보이면 메뉴 **File → Add Packages…** 로 같은 창을 열고 다시 하단을 확인합니다.
5. Finder에서 레포의 `Ping/ios/Packages/CoreModels` 폴더 선택 → **Add Package**  
   - **부모 폴더 `Packages`만 고르면 안 됩니다.** 반드시 **`CoreModels`처럼 `Package.swift`가 들어 있는 폴더**를 골라야 합니다.
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
   **`+`를 눌러 아래 제품을 앱에 전부 넣습니다.** (하나라도 빠지면 `No such module '…'`가 납니다.)

   - `CoreModels`
   - `CoreNetworking`
   - `CorePersistence`
   - `CoreDI`  ← `PingAppEntry.swift`가 `import CoreDI` 하므로 **필수**
   - `CoreUI`
   - `AuthFeature`
   - `MatchingFeature`
   - `RoomFeature`
   - `InteractionFeature`
   - (선택) `ProfileFeature`

   **Embed**는 모두 **Do Not Embed** 그대로 두면 됩니다.

8. 추가가 끝나면 **Package Dependencies** 탭에 `CoreModels`, `AuthFeature` 같은 이름이 **한 줄씩** 보여야 정상입니다.

---

## 3-보충-B Run 시 **`No such module 'CoreDI'`** 만 날 때

의미: **`CoreDI` 패키지가 SPM에 없거나**, 있어도 **앱 타깃에 `CoreDI` 라이브러리가 링크되지 않음**.

### 확인 순서

1. **프로젝트 → Package Dependencies** 에 **`CoreDI`** 가 보이나요?  
   - **없으면**: `+` → **Add Local…** → `ios/Packages/CoreDI` 폴더 선택 후 추가.

2. **TARGETS → 앱 → General → Frameworks, Libraries, and Embedded Content**  
   - 목록에 **`CoreDI`** 가 있는지 확인.  
   - **없으면 `+`** → 목록에서 **`CoreDI`** 선택 → **Add**.

3. **Product → Clean Build Folder** (⇧⌘K) 후 **Run** (⌘R).

4. 그래도 같으면 **File → Packages → Resolve Package Versions** 한 번 실행.

---

## 3-보충 (필독) `Package Dependencies`가 **완전 비어 있을** 때

왼쪽 네비게이터에 **`Packages` 폴더**가 생겼는데, **프로젝트 설정의 Package Dependencies 탭은 비어 있다**면, 대부분 **Swift Package가 아니라 폴더만 프로젝트에 넣은 상태**입니다. (`Add Files to "Ping"…` 로 `ios/Packages`를 끌어 넣은 경우 등)

### 고치는 순서

1. 왼쪽에서 잘못 들어온 **`Packages` 그룹**(또는 그 안의 패키지 폴더들)을 선택합니다.
2. **Delete** 키 또는 우클릭 → **Delete**  
3. 뜨는 창에서 **Remove References** 를 선택합니다. (**Move to Trash**는 디스크의 Git 파일까지 지울 수 있으니, 레포 안 파일이면 보통 **Remove References**만 선택)
4. 위 **3번 절차**대로 다시: **Package Dependencies → + → Add Local…** 으로 **`CoreModels`부터 한 개씩**만 추가합니다.

이후 **Package Dependencies**에 목록이 생기면 성공입니다.

---

## 3-보충 Target Membership 은 어디 있나요?

**어떤 소스 파일이 앱 빌드에 포함되는지** 보는 곳입니다.

1. 왼쪽 네비게이터에서 **파일 하나** 클릭 (예: `PingApp.swift`)
2. Xcode **오른쪽 패널**이 안 보이면: 메뉴 **View → Inspectors → Show Inspectors** (또는 **⌥⌘0**)
3. 오른쪽 패널 위쪽 아이콘 중 **첫 번째(종이 한 장 모양)** = **File Inspector** (단축키 **⌥⌘1**)
4. 아래로 스크롤하면 **Target Membership** 이라는 표가 있습니다.  
   - 앱 타깃 이름 옆 **체크박스**가 켜져 있으면 그 파일이 앱에 포함됩니다.

**SPM으로 제대로 연결한 패키지 소스**는 보통 여기서 앱 타깃에 **직접 체크하지 않습니다.**  
`Packages` 아래 파일들에 앱 타깃 체크가 **잔뜩** 있으면, 폴더만 추가된 쪽에 가깝습니다.

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

## 5-보충 실제 아이폰에서 **`Failed to send startMatching`** 일 때

### 1) URL을 맥 주소로 바꾸기

- **`127.0.0.1` / `localhost`는 아이폰에서 맥이 아닙니다.** (폰 자신을 가리킵니다.)
- 맥 터미널에서 IP 확인: `ipconfig getifaddr en0` (Wi‑Fi가 en0일 때)
- **Info**의 `API_BASE_URL`, `WS_BASE_URL`을 모두 그 IP로 맞춥니다.  
  예: `http://192.168.0.12:8000`, `ws://192.168.0.12:8000/ws`

### 2) 맥 방화벽

- 시스템 설정에서 **8000 포트**로 들어오는 연검이 막히지 않았는지 확인합니다.

### 3) 로컬 HTTP / WebSocket — ATS (App Transport Security)

`http://` + 사설 IP(`192.168.x.x`) 조합은 iOS가 막을 수 있습니다. **디버그/MVP용**으로 Info에 아래를 추가합니다.

1. **TARGETS → 앱 → Info → Custom iOS Target Properties** 에서 **+**
2. Key에 **`App Transport Security Settings`** 선택 (타입 Dictionary)
3. 방금 만든 항목을 펼치고 **+** 로 하위 항목 추가
4. Key: **`Allow Local Networking`** (내부 키 `NSAllowsLocalNetworking`) → **YES**

(원시 키로는 `NSAppTransportSecurity` 딕셔너리 안에 `NSAllowsLocalNetworking` = `YES`.)

### 4) “아이폰만 있는데 매칭 2명을 어떻게?”

**아이폰 하나로 ‘시뮬레이터’를 돌리는 건 아닙니다.** 매칭 테스트는 **클라이언트 2개**가 필요합니다.

- **방법 A**: Xcode에서 **시뮬레이터 하나 더 실행** (다른 기종 선택 후 Run) → 시뮬 + 실제 아이폰 둘 다 같은 Wi‑Fi, 둘 다 Info를 **맥 IP**로 설정  
- **방법 B**: 아이폰 두 대  
- **방법 C**: 맥 브라우저에서 간단한 WS 테스트 페이지 (별도 도구)

앱 코드는 **전송 직전에 WebSocket `connect()`를 다시 호출**하도록 되어 있어, 연결 전에 Ping을 눌러도 실패하기 어렵게 맞춰 두었습니다.

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

## 8-보충 시뮬레이터 1대 + 실제 아이폰 1대로 매칭하기 (클릭 순서)

매칭은 서버에 **대기 중인 사람이 2명**일 때 잡히므로, **시뮬 한 대 + 아이폰 한 대**가 가장 이해하기 쉽습니다.

### 준비 (한 번만)

1. 맥과 아이폰이 **같은 Wi‑Fi**에 붙어 있게 합니다. (USB로만 연결해도 되지만, **`http://맥IP`로 통신**하려면 보통 같은 LAN이 안전합니다.)
2. 맥 터미널에서 IP 확인: `ipconfig getifaddr en0`  
   예: `192.168.0.12`
3. **TARGETS → 앱 → Info** 에서 **시뮬과 아이폰이 같은 빌드**를 쓰므로, URL은 **둘 다 맥 IP**로 통일하는 것을 권장합니다.
   - `API_BASE_URL` = `http://192.168.0.12:8000` (본인 IP)
   - `WS_BASE_URL` = `ws://192.168.0.12:8000/ws`
   - 이렇게 하면 시뮬에서 `127.0.0.1` / 폰에서 맥 IP 를 따로 기억할 필요가 없습니다.
4. **5-보충**대로 **`Allow Local Networking` = YES** (ATS) 넣어 두었는지 확인합니다.
5. 서버는 반드시 **`--host 0.0.0.0`** 로 떠 있어야 합니다. (다른 기기에서 맥으로 붙을 수 있게)

### A. 시뮬레이터에 앱 올리기

1. Xcode 상단 **실행 대상**에서 **iPhone 시뮬레이터** 선택 (예: iPhone 14 Pro)
2. **▶ Run**
3. 앱에서 **닉네임 등록**까지 완료 (예: `sim1`)
4. **Ping 화면까지** 나와 두고, **아직 Ping 버튼은 누르지 않아도** 됩니다.

### B. 아이폰에 같은 앱 올리기

1. 아이폰 **USB** 연결
2. Xcode 상단 **실행 대상**을 **본인 아이폰 이름**으로 변경
3. **▶ Run**
4. “**already running / Replace**” 가 뜨면 **Replace** 눌러도 됩니다.  
   의미: Xcode 디버그 연결을 **아이폰 쪽으로 옮기는 것**이고, **시뮬레이터에 깔린 앱은 대개 그대로** 남습니다.
5. 아이폰에서 앱 실행 → **다른 닉네임** 등록 (예: `phone1`)

### C. 매칭 시키기

1. **시뮬레이터** 창을 앞으로 가져와 **Ping** 버튼 탭  
2. **아이폰**에서 **Ping** 버튼 탭  
3. 잠시 후 둘 다 **Room** 화면으로 넘어가면 성공입니다.

### 잘 안 될 때

- 아이폰 Safari에서 `http://맥IP:8000/docs` 가 열리는지 확인 (안 열리면 Wi‑Fi/방화벽/IP 오타)
- 시뮬에서도 같은 URL을 쓰는데 안 되면, 맥 방화벽에서 **Python / uvicorn** 허용 여부 확인

---

## 문제가 자주 나는 것

- **Package Dependencies가 비어 있음**: **3-보충** 참고 (폴더만 추가된 상태 → Remove References 후 Add Local로 재연결)
- **“No such module AuthFeature” 등**: Package Dependencies에 패키지가 보인 뒤, **General → Frameworks, Libraries** 에서 해당 제품(예: `AuthFeature`) **+** 로 추가
- **`Multiple commands produce … stringsdata`**: 같은 `.swift`가 두 번 빌드됨 → **Build Phases → Compile Sources** 에서 중복 제거, `PingApp.swift` 두 벌 없애기
- **`@main` 중복**: `PingAppApp.swift` 삭제 또는 `@main` 제거
- **WebSocket 연결 실패 / `Failed to send startMatching`**: 실기기는 **맥 IP** + **ATS `Allow Local Networking`** → **5-보충** 참고. 서버는 `--host 0.0.0.0` 로 떠 있어야 함.
