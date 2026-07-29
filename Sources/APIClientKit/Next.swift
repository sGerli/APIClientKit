/// Represents the next handler in a middleware chain.
///
/// Middleware receive a `Next` value and call ``respond(to:)`` to forward
/// the endpoint down the chain. The innermost handler is always
/// ``APIClientProtocol/makeRequest(endpoint:)``.
///
/// Middleware may call ``respond(to:)`` more than once to implement retry logic.
public struct Next: @unchecked Sendable {
    // Untyped throws here is intentional: when middleware.intercept is called through
    // an `any APIClientMiddleware` existential, Swift erases the typed throw
    // (APIClientError) to `any Error`. Using an untyped closure avoids a
    // compile-time mismatch while the typed guarantee is restored in respond(to:).
    private let _respond: (any Endpoint) async throws -> Response

    public init(_ respond: @escaping (any Endpoint) async throws -> Response) {
        self._respond = respond
    }

    /// Forwards the endpoint to the next handler in the chain.
    ///
    /// - Parameter endpoint: The endpoint to forward. Middleware may substitute
    ///   a modified endpoint if needed.
    /// - Returns: The raw ``Response`` from the next handler.
    ///   Status codes are **not** filtered at this point, giving middleware
    ///   full visibility into every response (including `4xx`/`5xx`).
    /// Forwards the endpoint to the next handler and re-surfaces any error as a
    /// typed ``APIClientError``, restoring the typed-throws guarantee at the
    /// public boundary despite the untyped storage closure inside.
    public func respond(to endpoint: any Endpoint) async throws(APIClientError) -> Response {
        do {
            return try await _respond(endpoint)
        } catch let error as APIClientError {
            throw error
        } catch {
            throw APIClientError.requestError(endpoint, error)
        }
    }
}
