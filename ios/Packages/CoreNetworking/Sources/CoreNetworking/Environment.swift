import Foundation

public struct ServerEnvironment: Sendable, Equatable {
    public let apiBaseURL: URL
    public let wsBaseURL: URL

    public init(apiBaseURL: URL, wsBaseURL: URL) {
        self.apiBaseURL = apiBaseURL
        self.wsBaseURL = wsBaseURL
    }
}

