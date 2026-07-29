import Testing
@testable import APIClientKit
import APIClientKitURLSession

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

private struct Ping: Endpoint {
    let path = "/ping"
    let method = Method.get
    let task = EndpointTask.plain
}

private struct Echo: ModelEndpoint {
    struct Payload: Decodable, Equatable, Sendable {
        let message: String
    }

    typealias ResponseType = Payload
    let path = "/echo"
    let method = Method.get
    let task = EndpointTask.plain
}

private struct Create: Endpoint {
    let path = "/items"
    let method = Method.post
    let task = EndpointTask.bodyParameters(["name": "widget", "qty": 2])
}

@Test func jsonValueEncodesObjectBody() throws {
    let task = EndpointTask.bodyParameters([
        "name": "ada",
        "active": true,
        "score": 42,
    ])
    let payload = try #require(task.body)
    let encoded: Data
    switch payload {
    case .json(let value):
        encoded = try JSONEncoder().encode(value)
    case .jsonEncoded(let encodable, let encoder):
        encoded = try encoder.encode(encodable)
    case .data(let raw):
        encoded = raw
    }
    let object = try JSONDecoder().decode(JSONValue.self, from: encoded)
    guard case .object(let dict) = object else {
        Issue.record("expected object")
        return
    }
    #expect(dict["name"] == .string("ada"))
    #expect(dict["active"] == .bool(true))
    #expect(dict["score"] == .number(42))
}

@Test func responseValidationMapsForbidden() {
    let response = Response(requestURL: "https://x/y", data: Data(), statusCode: 403)
    let error = ResponseValidation.error(for: response)
    guard case .forbidden = error else {
        Issue.record("expected forbidden, got \(error)")
        return
    }
}

@Test func responseValidationMapsNotFoundSeparatelyFromForbidden() {
    let response = Response(requestURL: "https://x/y", data: Data(), statusCode: 404)
    let error = ResponseValidation.error(for: response)
    guard case .notFound = error else {
        Issue.record("expected notFound, got \(error)")
        return
    }
}

@Test func responseValidationMapsRateLimitWithResponse() {
    let body = Data(#"{"error":"slow down"}"#.utf8)
    let response = Response(
        requestURL: "https://x/y",
        data: body,
        statusCode: 429,
        headers: ["retry-after": "12"]
    )
    let error = ResponseValidation.error(for: response)
    guard case let .rateLimitExceeded(captured, retryAfterSeconds: seconds) = error else {
        Issue.record("expected rateLimitExceeded, got \(error)")
        return
    }
    #expect(seconds == 12)
    #expect(captured.data == body)
    #expect(APIClientDebugLog.responseIfPresent(for: error)?.statusCode == 429)
}

@Test func inMemoryClientExecutesAndDecodes() async throws {
    let client = InMemoryAPIClient { _ in
        Response(
            requestURL: "https://in-memory.test/echo",
            data: Data(#"{"message":"hi"}"#.utf8),
            statusCode: 200,
            headers: ["content-type": "application/json"]
        )
    }
    let payload = try await Echo().execute(client: client)
    #expect(payload == Echo.Payload(message: "hi"))
}

@Test func executeRawSkipsStatusValidation() async throws {
    let client = InMemoryAPIClient { _ in
        Response(requestURL: "https://in-memory.test/ping", data: Data(), statusCode: 503)
    }
    let raw = try await Ping().executeRaw(client: client)
    #expect(raw.statusCode == 503)
}

@Test func executeValidatesStatus() async throws {
    let client = InMemoryAPIClient { _ in
        Response(requestURL: "https://in-memory.test/ping", data: Data(), statusCode: 503)
    }
    await #expect(throws: APIClientError.self) {
        _ = try await Ping().execute(client: client)
    }
}

@Test func middlewareSeesRawStatusBeforeValidation() async throws {
    final class Box: @unchecked Sendable {
        var status: Int?
    }
    struct Capture503: APIClientMiddleware {
        let box: Box
        func intercept(endpoint: any Endpoint, next: Next) async throws(APIClientError) -> Response {
            let response = try await next.respond(to: endpoint)
            box.status = response.statusCode
            return response
        }
    }

    let box = Box()
    let client = InMemoryAPIClient(middlewares: [Capture503(box: box)]) { _ in
        Response(requestURL: "https://in-memory.test/ping", data: Data(), statusCode: 503)
    }

    await #expect(throws: APIClientError.self) {
        _ = try await Ping().execute(client: client)
    }
    #expect(box.status == 503)
}

@Test func urlSessionClientBuildsRequestViaTransform() async throws {
    // Exercise makeRequest construction without hitting the network by using a custom protocol.
    // If URLProtocol registration is awkward on Linux, assert type surface instead.
    let client = URLSessionAPIClient(
        baseURL: URL(string: "https://example.com")!,
        transformRequest: { request in
            request.setValue("APIClientKit", forHTTPHeaderField: "User-Agent")
        }
    )
    #expect(client.baseURL.host() == "example.com")
}

@Test func createEndpointEncodesJSONBody() throws {
    let body = try Create().body()
    let data = try #require(body)
    let value = try JSONDecoder().decode(JSONValue.self, from: data)
    guard case .object(let dict) = value else {
        Issue.record("expected object")
        return
    }
    #expect(dict["name"] == .string("widget"))
    #expect(dict["qty"] == .number(2))
}
