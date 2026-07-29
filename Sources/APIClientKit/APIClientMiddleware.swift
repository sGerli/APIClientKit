/// A composable unit of request/response interception.
///
/// Conform to this protocol to add cross-cutting concerns — such as rate limiting,
/// authentication refresh, logging, or generic retry — to any
/// ``APIClientProtocol`` conformer without modifying its core implementation.
///
/// Middleware are executed in declaration order. Given:
/// ```
/// middlewares = [A, B, C]
/// ```
/// The call order is:
/// ```
/// A.intercept → B.intercept → C.intercept → makeRequest
/// ```
///
/// ## Implementing a Middleware
///
/// ```swift
/// struct LoggingMiddleware: APIClientMiddleware {
///     func intercept(
///         endpoint: any Endpoint,
///         next: Next
///     ) async throws(APIClientError) -> Response {
///         print("→ \(endpoint.method.rawValue) \(endpoint.path)")
///         let response = try await next.respond(to: endpoint)
///         print("← \(response.statusCode)")
///         return response
///     }
/// }
/// ```
///
/// ## Retry Example
///
/// Because ``Next/respond(to:)`` can be called multiple times, middleware can
/// implement retry by calling it in a loop:
///
/// ```swift
/// func intercept(endpoint: any Endpoint, next: Next) async throws(APIClientError) -> Response {
///     for attempt in 1...maxRetries {
///         let response = try await next.respond(to: endpoint)
///         if response.statusCode != 503 { return response }
///         try await Task.sleep(for: .seconds(attempt))
///     }
///     throw .serverError(try await next.respond(to: endpoint))
/// }
/// ```
public protocol APIClientMiddleware: Sendable {

    /// Intercepts an outgoing request and its eventual response.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint about to be executed.
    ///   - next: The next handler in the chain. Call ``Next/respond(to:)``
    ///     to forward the request. You may pass a different endpoint if needed.
    /// - Returns: The ``Response`` to surface to the caller. This can be the
    ///   response returned by `next`, a cached response, or a synthesised one.
    /// - Throws: An ``APIClientError`` to abort the request and propagate an
    ///   error to the caller instead of returning a response.
    func intercept(
        endpoint: any Endpoint,
        next: Next
    ) async throws(APIClientError) -> Response
}
