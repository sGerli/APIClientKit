#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import APIClientKit

/// An `APIClientProtocol` adapter backed by `URLSession`.
///
/// Request mutation belongs here (not on the core protocol): use `transformRequest`
/// to adjust the wire `URLRequest` before it is sent.
public struct URLSessionAPIClient: APIClientProtocol {
    public let baseURL: URL
    public let jsonDecoder: JSONDecoder
    public let middlewares: [any APIClientMiddleware]
    public let session: URLSession
    public let transformRequest: @Sendable (inout URLRequest) -> Void

    public init(
        baseURL: URL,
        session: URLSession = .shared,
        jsonDecoder: JSONDecoder = JSONDecoder(),
        middlewares: [any APIClientMiddleware] = [],
        transformRequest: @escaping @Sendable (inout URLRequest) -> Void = { _ in }
    ) {
        self.baseURL = baseURL
        self.session = session
        self.jsonDecoder = jsonDecoder
        self.middlewares = middlewares
        self.transformRequest = transformRequest
    }

    public func makeRequest(endpoint: any Endpoint) async throws(APIClientError) -> Response {
        let url = try endpoint.url(baseURL: baseURL)

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        if let headers = endpoint.headers {
            for (name, value) in headers {
                request.setValue(value, forHTTPHeaderField: name)
            }
        }

        request.httpBody = try endpoint.body()

        transformRequest(&request)

        let headersForLog = lowercaseHeaders(from: request.allHTTPHeaderFields ?? [:])
        APIClientDebugLog.logWireRequestStartIfPresent(
            endpoint: endpoint,
            requestURL: url.absoluteString,
            headersLowercased: headersForLog,
            body: request.httpBody
        )

        let data: Data
        let urlResponse: URLResponse
        do {
            (data, urlResponse) = try await session.data(for: request)
        } catch {
            throw APIClientError.networkError(endpoint, error)
        }

        guard let http = urlResponse as? HTTPURLResponse else {
            throw APIClientError.requestError(
                endpoint,
                URLSessionAPIClientError.nonHTTPResponse
            )
        }

        return Response(
            requestURL: url.absoluteString,
            data: data,
            statusCode: http.statusCode,
            headers: lowercaseHeaders(from: http)
        )
    }
}

public enum URLSessionAPIClientError: Error, Sendable {
    case nonHTTPResponse
}

private func lowercaseHeaders(from fields: [String: String]) -> [String: String] {
    var out: [String: String] = [:]
    out.reserveCapacity(fields.count)
    for (key, value) in fields {
        out[key.lowercased()] = value
    }
    return out
}

private func lowercaseHeaders(from response: HTTPURLResponse) -> [String: String] {
    var out: [String: String] = [:]
    out.reserveCapacity(response.allHeaderFields.count)
    for (key, value) in response.allHeaderFields {
        guard let name = key as? String else { continue }
        out[name.lowercased()] = String(describing: value)
    }
    return out
}
