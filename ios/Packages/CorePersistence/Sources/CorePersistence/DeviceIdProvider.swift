import Foundation

public protocol DeviceIdProviding: Sendable {
    func getOrCreateDeviceId() throws -> String
}

public final class KeychainDeviceIdProvider: DeviceIdProviding {
    private let keychain: Keychain
    private let account: String

    public init(keychain: Keychain, account: String = "deviceId") {
        self.keychain = keychain
        self.account = account
    }

    public func getOrCreateDeviceId() throws -> String {
        if let existing = try keychain.readString(account: account), !existing.isEmpty {
            return existing
        }
        let new = UUID().uuidString.lowercased()
        try keychain.upsertString(new, account: account)
        return new
    }
}

