import Foundation

public protocol HTTPClient: Sendable {
    func get<T: Decodable>(_ path: String, query: [URLQueryItem]) async throws -> T
    func post<Body: Encodable, T: Decodable>(_ path: String, body: Body) async throws -> T
}

public final class URLSessionHTTPClient: HTTPClient {
    private let baseURL: URL
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    public func get<T: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        var comps = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        if !query.isEmpty { comps?.queryItems = query }
        guard let url = comps?.url else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, resp) = try await session.data(for: req)
        try validate(resp: resp, data: data)
        return try decoder.decode(T.self, from: data)
    }

    public func post<Body: Encodable, T: Decodable>(_ path: String, body: Body) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.httpBody = try encoder.encode(body)
        let (data, resp) = try await session.data(for: req)
        try validate(resp: resp, data: data)
        return try decoder.decode(T.self, from: data)
    }

    private func validate(resp: URLResponse, data: Data) throws {
        guard let http = resp as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw HTTPError(statusCode: http.statusCode, body: body)
        }
    }
}

public struct HTTPError: Error, Sendable {
    public let statusCode: Int
    public let body: String
}

