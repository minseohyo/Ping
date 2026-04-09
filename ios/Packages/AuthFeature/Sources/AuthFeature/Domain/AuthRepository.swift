import Foundation

public struct Me: Codable, Sendable, Equatable {
    public let userId: String
    public let deviceId: String
    public let nickname: String
}

public protocol AuthRepository: Sendable {
    func register(deviceId: String, nickname: String) async throws -> Me
    func me(deviceId: String) async throws -> Me
}

