import Foundation
import CoreModels

public protocol WebSocketClient: AnyObject, Sendable {
    var events: AsyncStream<Envelope> { get }
    func connect() async
    func disconnect()
    func send(_ envelope: Envelope) async throws
}

public final class URLSessionWebSocketClient: WebSocketClient {
    private let url: URL
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var task: URLSessionWebSocketTask?
    private let stream: AsyncStream<Envelope>
    private let continuation: AsyncStream<Envelope>.Continuation

    public var events: AsyncStream<Envelope> { stream }

    public init(url: URL, session: URLSession = .shared) {
        self.url = url
        self.session = session
        var cont: AsyncStream<Envelope>.Continuation!
        self.stream = AsyncStream<Envelope> { c in cont = c }
        self.continuation = cont
    }

    public func connect() async {
        guard task == nil else { return }
        let t = session.webSocketTask(with: url)
        self.task = t
        t.resume()
        receiveLoop()
    }

    public func disconnect() {
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
    }

    public func send(_ envelope: Envelope) async throws {
        guard let task else { throw URLError(.notConnectedToInternet) }
        let data = try encoder.encode(envelope)
        try await task.send(.data(data))
    }

    private func receiveLoop() {
        guard let task else { return }
        task.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure:
                self.disconnect()
            case .success(let message):
                if let env = self.decode(message) {
                    self.continuation.yield(env)
                }
                self.receiveLoop()
            }
        }
    }

    private func decode(_ message: URLSessionWebSocketTask.Message) -> Envelope? {
        switch message {
        case .data(let data):
            return try? decoder.decode(Envelope.self, from: data)
        case .string(let str):
            guard let data = str.data(using: .utf8) else { return nil }
            return try? decoder.decode(Envelope.self, from: data)
        @unknown default:
            return nil
        }
    }
}

