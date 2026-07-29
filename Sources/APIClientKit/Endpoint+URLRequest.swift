#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension Endpoint {
    private var queryItems: [URLQueryItem] {
        guard let parameters = task.query, !parameters.isEmpty else {
            return []
        }
        return parameters.map { URLQueryItem(name: $0, value: $1) }
    }

    public func url(baseURL: URL) throws(APIClientError) -> URL {
        let path = self.path
        guard
            let url = URL(string: path, relativeTo: baseURL),
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        else {
            throw APIClientError.endpointPathError(self, path: path)
        }
        components.queryItems = queryItems

        return components.url ?? url
    }

    public func body() throws(APIClientError) -> Data? {
        guard let body = task.body else { return nil }
        do {
            return try encodeEndpointBody(body)
        } catch {
            throw APIClientError.bodyEncodingError(self, error)
        }
    }
}

fileprivate func encodeEndpointBody(_ payload: EndpointBodyPayload) throws -> Data {
    switch payload {
    case .json(let value):
        return try JSONEncoder().encode(value)
    case .jsonEncoded(let encodable, let encoder):
        return try encoder.encode(encodable)
    case .data(let data):
        return data
    }
}
