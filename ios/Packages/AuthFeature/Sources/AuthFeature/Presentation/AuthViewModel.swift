import Foundation
import CorePersistence

@MainActor
public final class AuthViewModel: ObservableObject {
    public enum State: Equatable {
        case loading
        case needsNickname(deviceId: String)
        case authenticated(me: Me)
        case error(message: String)
    }

    @Published public private(set) var state: State = .loading
    @Published public var nickname: String = ""

    private let deviceIdProvider: DeviceIdProviding
    private let repo: AuthRepository

    public init(deviceIdProvider: DeviceIdProviding, repo: AuthRepository) {
        self.deviceIdProvider = deviceIdProvider
        self.repo = repo
    }

    public func onAppear() {
        Task { await bootstrap() }
    }

    public func submitNickname() {
        Task { await register() }
    }

    private func bootstrap() async {
        do {
            let deviceId = try deviceIdProvider.getOrCreateDeviceId()
            do {
                let me = try await repo.me(deviceId: deviceId)
                state = .authenticated(me: me)
            } catch {
                state = .needsNickname(deviceId: deviceId)
            }
        } catch {
            state = .error(message: "Failed to load deviceId")
        }
    }

    private func register() async {
        guard case .needsNickname(let deviceId) = state else { return }
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            let me = try await repo.register(deviceId: deviceId, nickname: trimmed)
            state = .authenticated(me: me)
        } catch {
            state = .error(message: "Register failed")
        }
    }
}

