import SwiftUI
import CoreDI
import CoreModels
import CoreNetworking
import AuthFeature
import MatchingFeature
import RoomFeature
import InteractionFeature

/// App(Composition Root): 라우팅 + WebSocket 이벤트 분배. Feature 간 직접 import 없음.
@MainActor
final class AppRouter: ObservableObject {
    enum Route: Equatable {
        case auth
        case matching(me: Me, deviceId: String)
        case room(me: Me, deviceId: String, roomId: String, members: [Member])
    }

    @Published var route: Route = .auth
    @Published var selectedMember: Member?
    /// Room 화면과 시트가 **같은** ViewModel을 쓰도록 Composition Root에서 보관합니다.
    @Published var roomViewModel: RoomViewModel?
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
                        router.roomViewModel = nil
                        startGlobalEventLoop(deviceId: deviceId)
                        router.route = .matching(me: me, deviceId: deviceId)
                    }
                )

            case .matching(let me, let deviceId):
                MatchingView(
                    viewModel: MatchingViewModel(
                        deviceId: deviceId,
                        http: container.http,
                        onMatched: { roomId, members in
                            let vm = RoomViewModel(
                                deviceId: deviceId,
                                roomId: roomId,
                                initialMembers: members,
                                ws: container.ws
                            )
                            router.roomViewModel = vm
                            router.route = .room(me: me, deviceId: deviceId, roomId: roomId, members: members)
                        }
                    )
                )
                    .navigationTitle("Matching")

            case .room:
                if let vm = router.roomViewModel {
                    RoomView(
                        viewModel: vm,
                        onMemberSelected: { member in
                            router.selectedMember = member
                        }
                    )
                    .sheet(item: $router.selectedMember) { member in
                        EmojiPickerView { emojiId in
                            vm.sendEmoji(toUserId: member.userId, emojiId: emojiId)
                            router.selectedMember = nil
                        }
                    }
                } else {
                    ProgressView("Room 입장 중…")
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

            let vm = RoomViewModel(
                deviceId: deviceId,
                roomId: roomId,
                initialMembers: members,
                ws: container.ws
            )
            router.roomViewModel = vm

            if case .matching(let me, _) = router.route {
                router.route = .room(me: me, deviceId: deviceId, roomId: roomId, members: members)
            } else if case .room(let me, _, _, _) = router.route {
                router.route = .room(me: me, deviceId: deviceId, roomId: roomId, members: members)
            }

        case "roomStateUpdated", "emojiReceived":
            router.roomViewModel?.handleEvent(env)

        default:
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
