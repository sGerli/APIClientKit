#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

public enum Method: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

public protocol Endpoint: Sendable {
    /// The path to be appended to `baseURL` to form the full `URL`.
    var path: String { get }

    /// The HTTP method used in the request.
    var method: Method { get }

    /// The type of HTTP task to be performed.
    var task: EndpointTask { get }

    /// The headers to be used in the request.
    var headers: [String: String]? { get }
}

public extension Endpoint {
    var headers: [String: String]? { nil }
}

public protocol ModelEndpoint<ResponseType>: Endpoint {
    associatedtype ResponseType

    func mapResponse(from data: Data, decoder: JSONDecoder) throws(APIClientError) -> ResponseType
}

public extension ModelEndpoint where ResponseType: Decodable {
    func mapResponse(from data: Data, decoder: JSONDecoder) throws(APIClientError) -> ResponseType {
        do {
            return try decoder.decode(ResponseType.self, from: data)
        } catch {
            throw .decodingError(self, error)
        }
    }
}

public protocol VoidEndpoint: Endpoint { }
