import Foundation
import CoreModels
import CoreNetworking
import CorePersistence

public protocol ServerConfigProviding: Sendable {
    var environment: ServerEnvironment { get }
}

public final class StaticServerConfigProvider: ServerConfigProviding {
    public let environment: ServerEnvironment
    public init(environment: ServerEnvironment) { self.environment = environment }
}

public final class AppContainer: @unchecked Sendable {
    public let config: ServerConfigProviding

    public let keychain: Keychain
    public let deviceIdProvider: DeviceIdProviding

    public let http: HTTPClient
    public let ws: WebSocketClient

    public init(config: ServerConfigProviding) {
        self.config = config
        self.keychain = Keychain(service: "Ping")
        self.deviceIdProvider = KeychainDeviceIdProvider(keychain: keychain)
        self.http = URLSessionHTTPClient(baseURL: config.environment.apiBaseURL)
        self.ws = URLSessionWebSocketClient(url: config.environment.wsBaseURL)
    }
}

