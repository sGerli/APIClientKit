#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension Endpoint {
    /// Executes through middleware and returns the raw ``Response`` (no status validation).
    public func executeRaw(client: any APIClientProtocol) async throws(APIClientError) -> Response {
        try await client.execute(endpoint: self)
    }

    /// Middleware + status validation.
    func validatedResponse(client: any APIClientProtocol) async throws(APIClientError) -> Response {
        try await ResponseValidation.validate(executeRaw(client: client))
    }

    /// Executes through middleware, validates the status code, and returns the response body.
    public func execute(client: any APIClientProtocol) async throws(APIClientError) -> Data {
        try await validatedResponse(client: client).data
    }
}

extension ModelEndpoint {
    /// Executes, validates status, and decodes ``ResponseType`` with the client's decoder.
    public func execute(client: any APIClientProtocol) async throws(APIClientError) -> ResponseType {
        try mapResponse(
            from: try await validatedResponse(client: client).data,
            decoder: client.jsonDecoder
        )
    }
}

extension VoidEndpoint {
    /// Executes and validates status; discards the body.
    public func execute(client: any APIClientProtocol) async throws(APIClientError) {
        _ = try await validatedResponse(client: client)
    }
}
