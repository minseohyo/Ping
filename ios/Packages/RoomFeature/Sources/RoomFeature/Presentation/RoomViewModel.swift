import Foundation
import CoreModels
import CoreNetworking

@MainActor
public final class RoomViewModel: ObservableObject {
    @Published public private(set) var members: [Member] = []
    @Published public private(set) var floatingEmojiByUserId: [String: String] = [:]

    private let deviceId: String
    private let roomId: String
    private let ws: WebSocketClient

    public init(deviceId: String, roomId: String, initialMembers: [Member], ws: WebSocketClient) {
        self.deviceId = deviceId
        self.roomId = roomId
        self.ws = ws
        self.members = initialMembers
    }

    public func onAppear() {
        Task {
            await ws.connect()
            try? await joinRoom()
        }
    }

    public func handleEvent(_ env: Envelope) {
        guard env.version == 1 else { return }
        switch env.type {
        case "roomStateUpdated":
            if let payload = env.payload.objectValue,
               case .string(let rid) = payload["roomId"],
               rid == roomId,
               case .array(let arr) = payload["members"] {
                let decoded = arr.compactMap { try? decodeMember($0) }
                self.members = decoded
            }
        case "emojiReceived":
            guard let payload = env.payload.objectValue,
                  case .string(let rid) = payload["roomId"],
                  rid == roomId,
                  case .string(let to) = payload["to"],
                  case .string(let emojiId) = payload["emojiId"]
            else { return }
            showEmoji(emojiId, to: to)
        default:
            break
        }
    }

    public func sendEmoji(toUserId: String, emojiId: String) {
        Task {
            let payload: JSONValue = .object([
                "deviceId": .string(deviceId),
                "toUserId": .string(toUserId),
                "emojiId": .string(emojiId)
            ])
            try? await ws.send(Envelope(type: "sendEmoji", payload: payload))
        }
    }

    private func joinRoom() async throws {
        let payload: JSONValue = .object([
            "deviceId": .string(deviceId),
            "roomId": .string(roomId)
        ])
        try await ws.send(Envelope(type: "joinRoom", payload: payload))
    }

    private func showEmoji(_ emojiId: String, to userId: String) {
        floatingEmojiByUserId[userId] = emojiId
        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            if floatingEmojiByUserId[userId] == emojiId {
                floatingEmojiByUserId[userId] = nil
            }
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

