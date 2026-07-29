#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// HTTP response surfaced to callers and middleware.
///
/// Transport-specific objects (e.g. `HTTPURLResponse`) stay inside adapters —
/// they are not part of this interface.
public struct Response: Sendable {
    public let requestURL: String
    public let data: Data
    public let statusCode: Int
    /// Response headers keyed by lowercase header name.
    /// When the server sends multiple values for the same field, the last value wins.
    public let headers: [String: String]

    public init(
        requestURL: String,
        data: Data,
        statusCode: Int,
        headers: [String: String] = [:]
    ) {
        self.requestURL = requestURL
        self.data = data
        self.statusCode = statusCode
        self.headers = headers
    }
}
