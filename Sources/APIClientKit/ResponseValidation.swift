#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Maps non-success HTTP status codes onto ``APIClientError``.
///
/// Middleware always sees raw responses. Status validation runs at the
/// ``Endpoint/execute(client:)`` seam so retry / auth middleware can inspect 4xx/5xx.
public enum ResponseValidation: Sendable {
    /// Accepts 2xx; otherwise throws the matching ``APIClientError``.
    @discardableResult
    public static func validate(_ response: Response) throws(APIClientError) -> Response {
        guard (200...299).contains(response.statusCode) else {
            throw error(for: response)
        }
        return response
    }

    public static func error(for response: Response) -> APIClientError {
        switch response.statusCode {
        case 400:
            return .badRequest(response)
        case 401:
            return .unauthorized(response)
        case 403:
            return .forbidden(response)
        case 404:
            return .notFound(response)
        case 422:
            return .unprocessableEntity(response)
        case 429:
            let retryAfter = response.headers["retry-after"].flatMap(Int.init) ?? 0
            return .rateLimitExceeded(response, retryAfterSeconds: retryAfter)
        case 500...599:
            return .serverError(response)
        default:
            return .unknownStatusCode(response)
        }
    }
}
