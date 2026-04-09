# Ping iOS (SwiftUI + MVVM + async/await)

이 디렉토리는 iOS 클라이언트 MVP를 위한 **SPM 모듈들(Core + Features)** 스캐폴딩을 포함합니다.
Windows 환경에서는 Xcode 프로젝트 생성/빌드가 불가하므로, 여기에는 **패키지 구조와 Swift 코드**를 먼저 고정합니다.

## Modules (SPM)

Core:
- `CoreModels`
- `CoreNetworking`
- `CorePersistence` (Keychain 포함)
- `CoreDI`
- `CoreUI`

Features:
- `AuthFeature`
- `MatchingFeature`
- `RoomFeature`
- `InteractionFeature`
- `ProfileFeature`

각 Feature는 `Presentation/Domain/Data` 구조를 따릅니다.

## Architecture constraints

- Feature 간 직접 의존 금지  
  - 화면 전환/이벤트 라우팅은 App(Composition Root)이 담당
- 클라 비즈니스 로직 최소화  
  - 클라는 Command 전송 + Event 렌더링에 집중

## Server config (Debug-friendly)

App 타깃에서 `Info.plist` 또는 `.xcconfig`로 아래 값을 주입하는 것을 전제로 합니다:
- `API_BASE_URL` (예: `http://localhost:8000`)
- `WS_BASE_URL` (예: `ws://localhost:8000/ws`)

## Next

macOS/Xcode 환경에서:
1) SwiftUI App 프로젝트 생성
2) `ios/Packages/*`를 Local Package로 추가
3) App Target에서 `PingApp`(Composition Root) 코드를 추가/연결

