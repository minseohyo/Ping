import Foundation
import CoreModels
import CoreNetworking

@MainActor
public final class MatchingViewModel: ObservableObject {
    public enum State: Equatable {
        case idle
        case connecting
        case queued
        case error(String)
    }

    @Published public private(set) var state: State = .idle

    private let deviceId: String
    private let http: HTTPClient
    private let onMatched: (String, [Member]) -> Void

    public init(deviceId: String, http: HTTPClient, onMatched: @escaping (String, [Member]) -> Void) {
        self.deviceId = deviceId
        self.http = http
        self.onMatched = onMatched
    }

    public func onAppear() {
        state = .idle
    }

    public func ping() {
        Task {
            do {
                state = .connecting
                let result: MatchingStartResponse = try await http.post(
                    "/matching/start",
                    body: MatchingStartRequest(deviceId: deviceId, regionId: "default")
                )
                switch result.status {
                case "matched", "already_matched":
                    guard let roomId = result.roomId else {
                        state = .error("Matched without roomId")
                        return
                    }
                    onMatched(roomId, result.members ?? [])
                case "queued":
                    state = .queued
                default:
                    state = .error("Unexpected matching status: \(result.status)")
                }
            } catch {
                state = .error("Failed to start matching: \(error.localizedDescription)")
            }
        }
    }
}

private struct MatchingStartRequest: Encodable {
    let deviceId: String
    let regionId: String
}

private struct MatchingStartResponse: Decodable {
    let status: String
    let roomId: String?
    let members: [Member]?
}

