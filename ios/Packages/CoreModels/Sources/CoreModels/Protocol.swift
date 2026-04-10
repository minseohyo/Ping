import Foundation

public struct Envelope: Codable, Sendable, Equatable {
    public let type: String
    public let version: Int
    public let payload: JSONValue

    public init(type: String, version: Int = 1, payload: JSONValue) {
        self.type = type
        self.version = version
        self.payload = payload
    }
}

public struct Member: Codable, Sendable, Equatable, Hashable, Identifiable {
    public var id: String { userId }
    public let userId: String
    public let nickname: String
    public let avatarUrl: String?

    public init(userId: String, nickname: String, avatarUrl: String?) {
        self.userId = userId
        self.nickname = nickname
        self.avatarUrl = avatarUrl
    }
}

public enum JSONValue: Codable, Sendable, Equatable {
    case object([String: JSONValue])
    case array([JSONValue])
    case string(String)
    case number(Double)
    case bool(Bool)
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .object(let obj): try container.encode(obj)
        case .array(let arr): try container.encode(arr)
        case .string(let s): try container.encode(s)
        case .number(let n): try container.encode(n)
        case .bool(let b): try container.encode(b)
        case .null: try container.encodeNil()
        }
    }
}

public extension JSONValue {
    var objectValue: [String: JSONValue]? {
        if case .object(let o) = self { return o }
        return nil
    }
    var stringValue: String? {
        if case .string(let s) = self { return s }
        return nil
    }
}

