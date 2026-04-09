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
    private let ws: WebSocketClient

    public init(deviceId: String, ws: WebSocketClient) {
        self.deviceId = deviceId
        self.ws = ws
    }

    public func onAppear() {
        Task { await ws.connect(); state = .idle }
    }

    public func ping() {
        Task {
            do {
                state = .connecting
                let payload: JSONValue = .object([
                    "deviceId": .string(deviceId),
                    "regionId": .string("default")
                ])
                try await ws.send(Envelope(type: "startMatching", payload: payload))
                state = .queued
            } catch {
                state = .error("Failed to send startMatching")
            }
        }
    }
}

