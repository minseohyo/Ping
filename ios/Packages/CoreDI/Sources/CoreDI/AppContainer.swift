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

    /// Reads `API_BASE_URL` and `WS_BASE_URL` from the app Info.plist (add as custom keys in Xcode).
    public static func makeFromInfoPlist(bundle: Bundle = .main) -> AppContainer {
        let apiString = (bundle.object(forInfoDictionaryKey: "API_BASE_URL") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let wsString = (bundle.object(forInfoDictionaryKey: "WS_BASE_URL") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let api = (apiString?.isEmpty == false ? apiString! : "http://127.0.0.1:8000")
        let ws = (wsString?.isEmpty == false ? wsString! : "ws://127.0.0.1:8000/ws")

        guard let apiURL = URL(string: api), let wsURL = URL(string: ws) else {
            fatalError("Invalid API_BASE_URL or WS_BASE_URL in Info.plist")
        }
        let environment = ServerEnvironment(apiBaseURL: apiURL, wsBaseURL: wsURL)
        return AppContainer(config: StaticServerConfigProvider(environment: environment))
    }
}

