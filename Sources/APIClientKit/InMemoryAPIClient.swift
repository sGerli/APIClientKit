#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// In-memory ``APIClientProtocol`` adapter for tests and local fakes.
public struct InMemoryAPIClient: APIClientProtocol {
    public let baseURL: URL
    public let jsonDecoder: JSONDecoder
    public let middlewares: [any APIClientMiddleware]
    private let handler: @Sendable (any Endpoint) async throws -> Response

    public init(
        baseURL: URL = URL(string: "https://in-memory.test")!,
        jsonDecoder: JSONDecoder = JSONDecoder(),
        middlewares: [any APIClientMiddleware] = [],
        handler: @escaping @Sendable (any Endpoint) async throws -> Response
    ) {
        self.baseURL = baseURL
        self.jsonDecoder = jsonDecoder
        self.middlewares = middlewares
        self.handler = handler
    }

    public func makeRequest(endpoint: any Endpoint) async throws(APIClientError) -> Response {
        do {
            return try await handler(endpoint)
        } catch let error as APIClientError {
            throw error
        } catch {
            throw APIClientError.requestError(endpoint, error)
        }
    }
}
