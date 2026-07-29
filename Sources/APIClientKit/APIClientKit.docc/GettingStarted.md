# Getting Started

Build an ``Endpoint``, pick an adapter that conforms to ``APIClientProtocol``, then call `execute(client:)`.

## Declare an endpoint

```swift
import APIClientKit

struct Health: Endpoint {
    let path = "/health"
    let method = Method.get
    let task = EndpointTask.plain
}
```

For JSON response bodies, conform to ``ModelEndpoint`` and let the default decoder path run:

```swift
struct UserDTO: Decodable, Sendable {
    let id: String
    let name: String
}

struct GetUser: ModelEndpoint {
    typealias ResponseType = UserDTO
    let id: String

    var path: String { "/users/\(id)" }
    var method: Method { .get }
    var task: EndpointTask { .plain }
}
```

## Choose an adapter

- Production HTTP: add the `APIClientKitURLSession` product and use `URLSessionAPIClient`, unless you have a custom transport implementation.
- Tests / fakes: use ``InMemoryAPIClient``.

```swift
import APIClientKit

let client = InMemoryAPIClient { endpoint in
    Response(
        requestURL: "https://in-memory.test\(endpoint.path)",
        data: Data(#"{"id":"1","name":"Ada"}"#.utf8),
        statusCode: 200
    )
}

let user = try await GetUser(id: "1").execute(client: client)
```

## Raw vs validated execution

| API | Middleware | Status validation |
|---|---|---|
| `executeRaw(client:)` | yes | no |
| `execute(client:)` | yes | yes (``ResponseValidation``) |

Middleware always sees raw status codes so retry and auth refresh can inspect `401` / `429` / `503`.

## See also

- <doc:Architecture>
- <doc:MiddlewareGuide>
- <doc:ResponseValidationGuide>
