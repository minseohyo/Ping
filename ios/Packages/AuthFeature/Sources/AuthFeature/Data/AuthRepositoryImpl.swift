import Foundation
import CorePersistence
import CoreNetworking

public final class DefaultAuthRepository: AuthRepository {
    private let api: AuthAPI

    public init(http: HTTPClient) {
        self.api = AuthAPI(http: http)
    }

    public func register(deviceId: String, nickname: String) async throws -> Me {
        let r = try await api.register(deviceId: deviceId, nickname: nickname)
        return Me(userId: r.userId, deviceId: r.deviceId, nickname: r.nickname)
    }

    public func me(deviceId: String) async throws -> Me {
        let r = try await api.me(deviceId: deviceId)
        return Me(userId: r.userId, deviceId: r.deviceId, nickname: r.nickname)
    }
}

