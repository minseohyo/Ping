import SwiftUI
import CoreDI
import CoreModels
import CoreNetworking
import CorePersistence
import AuthFeature
import MatchingFeature
import RoomFeature
import InteractionFeature

/// NOTE:
/// - 이 파일은 "App 타깃(Composition Root)" 예시 스켈레톤입니다.
/// - Xcode SwiftUI App 프로젝트에 복사/참조하여 사용하세요.

@MainActor
final class AppRouter: ObservableObject {
    enum Route: Equatable {
        case auth
        case matching(me: Me, deviceId: String)
        case room(me: Me, deviceId: String, roomId: String, members: [Member])
    }

    @Published var route: Route = .auth
    @Published var selectedMember: Member?
}

public struct PingAppRootView: View {
    @StateObject private var router = AppRouter()
    private let container: AppContainer

    public init(container: AppContainer) {
        self.container = container
    }

    public var body: some View {
        NavigationStack {
            switch router.route {
            case .auth:
                AuthView(
                    viewModel: AuthViewModel(
                        deviceIdProvider: container.deviceIdProvider,
                        repo: DefaultAuthRepository(http: container.http)
                    ),
                    onAuthenticated: { me in
                        let deviceId = (try? container.deviceIdProvider.getOrCreateDeviceId()) ?? me.deviceId
                        startGlobalEventLoop(deviceId: deviceId)
                        router.route = .matching(me: me, deviceId: deviceId)
                    }
                )

            case .matching(let me, let deviceId):
                MatchingView(viewModel: MatchingViewModel(deviceId: deviceId, ws: container.ws))
                    .navigationTitle("Matching")

            case .room(let me, let deviceId, let roomId, let members):
                RoomView(
                    viewModel: RoomViewModel(deviceId: deviceId, roomId: roomId, initialMembers: members, ws: container.ws),
                    onMemberSelected: { member in
                        router.selectedMember = member
                    }
                )
                .sheet(item: $router.selectedMember) { member in
                    EmojiPickerView { emojiId in
                        // Interaction command stays thin: just forward to WS.
                        // RoomViewModel sends sendEmoji; we route it here to avoid Feature->Feature dependency.
                        // In practice you'd inject a small Interaction VM.
                        let vm = RoomViewModel(deviceId: deviceId, roomId: roomId, initialMembers: members, ws: container.ws)
                        vm.sendEmoji(toUserId: member.userId, emojiId: emojiId)
                        router.selectedMember = nil
                    }
                }
            }
        }
    }

    private func startGlobalEventLoop(deviceId: String) {
        Task {
            await container.ws.connect()

            for await env in container.ws.events {
                await MainActor.run {
                    handleEnvelope(deviceId: deviceId, env: env)
                }
            }
        }
    }

    private func handleEnvelope(deviceId: String, env: Envelope) {
        switch env.type {
        case "matched":
            guard let p = env.payload.objectValue,
                  case .string(let roomId) = p["roomId"],
                  case .array(let arr) = p["members"]
            else { return }
            let members = arr.compactMap { try? decodeMember($0) }

            // Transition to room, keep room fixed until leave.
            if case .matching(let me, _) = router.route {
                router.route = .room(me: me, deviceId: deviceId, roomId: roomId, members: members)
            }

        default:
            // Room-specific events are handled inside RoomViewModel (App can also fan-out if desired)
            break
        }
    }

    private func decodeMember(_ v: JSONValue) throws -> Member {
        guard let o = v.objectValue else { throw NSError() }
        guard let userId = o["userId"]?.stringValue else { throw NSError() }
        guard let nickname = o["nickname"]?.stringValue else { throw NSError() }
        let avatarUrl = o["avatarUrl"]?.stringValue
        return Member(userId: userId, nickname: nickname, avatarUrl: avatarUrl)
    }
}

