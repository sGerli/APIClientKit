#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Debug logging for outbound API calls: correlates `phase=start` (from wire transport) with `phase=end` / `phase=fail`.
public struct APIClientDebugLoggingMiddleware: APIClientMiddleware {
    public let baseURL: URL
    public let clientLabel: String
    public let log: @Sendable (String) -> Void

    public init(baseURL: URL, clientLabel: String, log: @escaping @Sendable (String) -> Void) {
        self.baseURL = baseURL
        self.clientLabel = clientLabel
        self.log = log
    }

    public func intercept(
        endpoint: any Endpoint,
        next: Next
    ) async throws(APIClientError) -> Response {
        let correlationID = UUID()
        let ctx = APIClientDebugLog.Context(
            correlationID: correlationID,
            clientLabel: clientLabel,
            log: log
        )
        let clockStart = ContinuousClock.now
        let method = endpoint.method.rawValue

        let urlForFail: String
        let urlResolved: Bool
        if let absolute = try? endpoint.url(baseURL: baseURL).absoluteString {
            urlForFail = absolute
            urlResolved = true
        } else {
            urlForFail = endpoint.path
            urlResolved = false
        }

        return try await Self.withDebugContext(ctx, endpoint: endpoint) {
            do {
                let response = try await next.respond(to: endpoint)
                let elapsedMs = Self.milliseconds(since: clockStart)
                let summary =
                    "method=\(method) url=\(response.requestURL) status=\(response.statusCode) bytes=\(response.data.count) elapsed_ms=\(elapsedMs)"
                APIClientDebugLog.emitSummaryAndPayloadSections(
                    clientLabel: clientLabel,
                    correlationID: correlationID,
                    phase: "end",
                    summaryFields: summary,
                    redactedHeaders: APIClientDebugLog.redactHeaders(response.headers),
                    body: response.data,
                    log: log
                )
                return response
            } catch let error as APIClientError {
                let elapsedMs = Self.milliseconds(since: clockStart)
                let token = APIClientDebugLog.debugToken(for: error)
                if let response = APIClientDebugLog.responseIfPresent(for: error) {
                    let summary =
                        "method=\(method) url=\(response.requestURL) error=\(token) elapsed_ms=\(elapsedMs)"
                    APIClientDebugLog.emitSummaryAndPayloadSections(
                        clientLabel: clientLabel,
                        correlationID: correlationID,
                        phase: "fail",
                        summaryFields: summary,
                        redactedHeaders: APIClientDebugLog.redactHeaders(response.headers),
                        body: response.data,
                        log: log
                    )
                } else {
                    let resolvedFlag = urlResolved ? "" : " url_resolved=false"
                    let summary =
                        "method=\(method) url=\(urlForFail)\(resolvedFlag) error=\(token) elapsed_ms=\(elapsedMs)"
                    APIClientDebugLog.emitSummaryAndPayloadSections(
                        clientLabel: clientLabel,
                        correlationID: correlationID,
                        phase: "fail",
                        summaryFields: summary,
                        redactedHeaders: [:],
                        body: nil,
                        log: log
                    )
                }
                throw error
            }
        }
    }

    /// Bridges `TaskLocal.withValue` (existential `Error`) back to `throws(APIClientError)`.
    private static func withDebugContext<T>(
        _ ctx: APIClientDebugLog.Context,
        endpoint: any Endpoint,
        operation: () async throws -> T
    ) async throws(APIClientError) -> T {
        do {
            return try await APIClientDebugLog.$context.withValue(ctx, operation: operation)
        } catch let error as APIClientError {
            throw error
        } catch {
            throw APIClientError.requestError(endpoint, error)
        }
    }

    private static func milliseconds(since start: ContinuousClock.Instant) -> Int {
        let elapsed = ContinuousClock.now - start
        return Int(elapsed / .milliseconds(1))
    }
}
