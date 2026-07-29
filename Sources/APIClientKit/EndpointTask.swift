#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

public enum EndpointBodyPayload: Sendable {
    /// JSON object / array tree encoded with `JSONEncoder`.
    case json(JSONValue)
    /// Codable model encoded with the given encoder.
    case jsonEncoded(any Encodable & Sendable, encoder: JSONEncoder = JSONEncoder())
    /// Raw body bytes.
    case data(Data)
}

public struct EndpointTask: Sendable {
    public var query: [String: String]?
    public var body: EndpointBodyPayload?

    public init(query: [String: String]? = nil, body: EndpointBodyPayload? = nil) {
        self.query = query
        self.body = body
    }

    public static var plain: EndpointTask {
        EndpointTask(query: nil, body: nil)
    }

    public static func queryParameters(parameters: [String: String]) -> EndpointTask {
        EndpointTask(query: parameters, body: nil)
    }

    public static func bodyParameters(_ object: [String: JSONValue]) -> EndpointTask {
        EndpointTask(query: nil, body: .json(.object(object)))
    }

    public static func jsonBody(_ value: JSONValue) -> EndpointTask {
        EndpointTask(query: nil, body: .json(value))
    }

    public static func jsonEncodedParameters(
        _ encodable: any Encodable & Sendable,
        encoder: JSONEncoder = JSONEncoder()
    ) -> EndpointTask {
        EndpointTask(query: nil, body: .jsonEncoded(encodable, encoder: encoder))
    }

    public static func data(_ data: Data) -> EndpointTask {
        EndpointTask(query: nil, body: .data(data))
    }

    public static func queryAndBody(query: [String: String], body: EndpointBodyPayload) -> EndpointTask {
        EndpointTask(query: query, body: body)
    }
}
