import Foundation
import CoreNetworking

struct RegisterRequest: Encodable {
    let deviceId: String
    let nickname: String
}

struct RegisterResponse: Decodable {
    let userId: String
    let deviceId: String
    let nickname: String
}

struct MeResponse: Decodable {
    let userId: String
    let deviceId: String
    let nickname: String
}

final class AuthAPI: @unchecked Sendable {
    private let http: HTTPClient
    init(http: HTTPClient) { self.http = http }

    func register(deviceId: String, nickname: String) async throws -> RegisterResponse {
        try await http.post("/auth/register", body: RegisterRequest(deviceId: deviceId, nickname: nickname))
    }

    func me(deviceId: String) async throws -> MeResponse {
        try await http.get("/me", query: [URLQueryItem(name: "deviceId", value: deviceId)])
    }
}

