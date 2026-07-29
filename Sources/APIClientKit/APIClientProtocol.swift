#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// The transport seam for this package: build a ``Response`` from an ``Endpoint``.
///
/// Concrete adapters (URLSession, in-memory, server-side HTTP clients) own any
/// wire-specific request types. Those types are **not** part of this interface.
public protocol APIClientProtocol: Sendable {
    var baseURL: URL { get }
    var jsonDecoder: JSONDecoder { get }
    /// Middleware executed in order for every request. Defaults to an empty array.
    var middlewares: [any APIClientMiddleware] { get }

    /// Performs the raw HTTP request without middleware or status validation.
    /// This is the innermost handler in the middleware chain.
    func makeRequest(endpoint: any Endpoint) async throws(APIClientError) -> Response
}

public extension APIClientProtocol {
    var middlewares: [any APIClientMiddleware] { [] }

    /// Runs the request through the middleware pipeline and calls ``makeRequest(endpoint:)``.
    /// Status codes are **not** filtered here — use ``Endpoint/execute(client:)`` for validated calls.
    func execute(endpoint: any Endpoint) async throws(APIClientError) -> Response {
        let base = Next { endpoint in
            try await self.makeRequest(endpoint: endpoint)
        }

        let chain = middlewares.reversed().reduce(base) { next, middleware in
            Next { endpoint in
                try await middleware.intercept(endpoint: endpoint, next: next)
            }
        }

        return try await chain.respond(to: endpoint)
    }
}
