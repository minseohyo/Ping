import SwiftUI
import CoreDI

/// Xcode App 타깃의 **@main**으로 이 파일만 지정하세요.
/// 기본 생성된 `*App.swift`의 `@main`은 제거하거나 파일에서 삭제하세요.
@main
struct PingApplication: App {
    private let container = AppContainer.makeFromInfoPlist()

    var body: some Scene {
        WindowGroup {
            PingAppRootView(container: container)
        }
    }
}
