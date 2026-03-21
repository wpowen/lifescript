import Foundation

/// API client skeleton prepared for V2 backend integration.
/// In MVP, all content is loaded from bundled JSON via ContentLoader.
final class APIClient: Sendable {
    static let shared = APIClient()

    private let session: URLSession
    private let baseURL: URL

    init(
        baseURL: URL = URL(string: "https://api.lifescript.app")!,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let request = try endpoint.urlRequest(baseURL: baseURL)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AppError.unknown
        }
        guard (200..<300).contains(http.statusCode) else {
            if http.statusCode == 401 { throw AppError.unauthorized }
            throw AppError.server(statusCode: http.statusCode, message: "Server error")
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw AppError.decoding(underlying: error)
        }
    }
}

struct APIEndpoint {
    enum HTTPMethod: String { case GET, POST, PUT, DELETE }
    let method: HTTPMethod
    let path: String
    var bodyEncoder: (() throws -> Data)?
    var queryItems: [URLQueryItem] = []

    func urlRequest(baseURL: URL) throws -> URLRequest {
        var url = baseURL.appending(path: path)
        if !queryItems.isEmpty {
            url.append(queryItems: queryItems)
        }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let bodyEncoder {
            request.httpBody = try bodyEncoder()
        }
        return request
    }
}
