#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Carries correlation and sink for one ``APIClientDebugLoggingMiddleware`` / `makeRequest` chain.
public enum APIClientDebugLog {
    public struct Context: Sendable {
        public let correlationID: UUID
        public let clientLabel: String
        public let log: @Sendable (String) -> Void

        public init(
            correlationID: UUID,
            clientLabel: String,
            log: @escaping @Sendable (String) -> Void
        ) {
            self.correlationID = correlationID
            self.clientLabel = clientLabel
            self.log = log
        }
    }

    @TaskLocal public static var context: Context?

    // MARK: - Wire start (called from Vapor transport after `transformRequest`)

    public static func logWireRequestStartIfPresent(
        endpoint: any Endpoint,
        requestURL: String,
        headersLowercased: [String: String],
        body: Data?
    ) {
        guard let ctx = context else { return }
        let method = endpoint.method.rawValue
        let summary = "method=\(method) url=\(requestURL)"
        emitSummaryAndPayloadSections(
            clientLabel: ctx.clientLabel,
            correlationID: ctx.correlationID,
            phase: "start",
            summaryFields: summary,
            redactedHeaders: redactHeaders(headersLowercased),
            body: body,
            log: ctx.log
        )
    }

    /// Emits one summary line, then headers and body each on their own lines (pretty-printed).
    public static func emitSummaryAndPayloadSections(
        clientLabel: String,
        correlationID: UUID,
        phase: String,
        summaryFields: String,
        redactedHeaders: [String: String],
        body: Data?,
        log: @Sendable (String) -> Void
    ) {
        let base = "APIClient client=\(clientLabel) corr=\(correlationID.uuidString) phase=\(phase)"
        log("\(base) \(summaryFields)")
        log("\(base) headers\n\(prettyPrintedHeadersJSON(redactedHeaders))")
        log("\(base) body\n\(prettyFormattedBody(body))")
    }

    // MARK: - Formatting

    public static func prettyPrintedHeadersJSON(_ headers: [String: String]) -> String {
        guard !headers.isEmpty else { return "{}" }
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(headers)
            return truncateForLog(String(decoding: data, as: UTF8.self))
        } catch {
            return "{\n  \"error\": \"headers_json_serialization_failed\"\n}"
        }
    }

    /// Pretty-prints JSON bodies; otherwise returns UTF-8 text (may be multi-line).
    public static func prettyFormattedBody(_ data: Data?) -> String {
        guard let data, !data.isEmpty else { return "(empty)" }
        guard let value = try? JSONDecoder().decode(JSONValue.self, from: data) else {
            return truncateForLog(String(decoding: data, as: UTF8.self))
        }
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let pretty = try encoder.encode(value)
            return truncateForLog(String(decoding: pretty, as: UTF8.self))
        } catch {
            return truncateForLog(String(decoding: data, as: UTF8.self))
        }
    }

    private static let maxPrettyLogScalars = 32_768

    private static func truncateForLog(_ string: String) -> String {
        guard string.unicodeScalars.count > maxPrettyLogScalars else { return string }
        let end = string.unicodeScalars.index(string.unicodeScalars.startIndex, offsetBy: maxPrettyLogScalars)
        return String(string.unicodeScalars[..<end]) + "\n…(truncated)"
    }

    public static func redactHeaders(_ headers: [String: String]) -> [String: String] {
        let redactKeys: Set<String> = ["authorization", "cookie", "set-cookie"]
        var out: [String: String] = [:]
        out.reserveCapacity(headers.count)
        for (key, value) in headers {
            if redactKeys.contains(key.lowercased()) {
                out[key] = "***"
            } else {
                out[key] = value
            }
        }
        return out
    }

    public static func debugToken(for error: APIClientError) -> String {
        switch error {
        case .badRequest: return "badRequest"
        case .unauthorized: return "unauthorized"
        case .forbidden: return "forbidden"
        case .notFound: return "notFound"
        case .unprocessableEntity: return "unprocessableEntity"
        case .rateLimitExceeded: return "rateLimitExceeded"
        case .serverError: return "serverError"
        case .unknownStatusCode: return "unknownStatusCode"
        case .networkError: return "networkError"
        case .requestError: return "requestError"
        case .decodingError: return "decodingError"
        case .endpointPathError: return "endpointPathError"
        case .bodyEncodingError: return "bodyEncodingError"
        }
    }

    public static func responseIfPresent(for error: APIClientError) -> Response? {
        switch error {
        case let .serverError(r),
            let .badRequest(r),
            let .unprocessableEntity(r),
            let .notFound(r),
            let .forbidden(r),
            let .unauthorized(r),
            let .unknownStatusCode(r),
            let .rateLimitExceeded(r, _):
            return r
        default:
            return nil
        }
    }
}
