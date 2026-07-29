# Using URLSession

`URLSessionAPIClient` conforms to APIClientKit’s `APIClientProtocol` and owns all `URLRequest` mutation.

## Install

```swift
dependencies: [
    .package(url: "https://github.com/sGerli/APIClientKit.git", from: "1.0.0")
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "APIClientKit", package: "APIClientKit"),
            .product(name: "APIClientKitURLSession", package: "APIClientKit"),
        ]
    )
]
```

On Linux this product links `FoundationNetworking`.

## Basic usage

```swift
import APIClientKit
import APIClientKitURLSession

let client = URLSessionAPIClient(
    baseURL: URL(string: "https://api.example.com")!,
    middlewares: [
        APIClientDebugLoggingMiddleware(
            baseURL: URL(string: "https://api.example.com")!,
            clientLabel: "example",
            log: { print($0) }
        )
    ],
    transformRequest: { request in
        request.setValue("Bearer …", forHTTPHeaderField: "Authorization")
    }
)

struct Health: Endpoint {
    let path = "/health"
    let method = Method.get
    let task = EndpointTask.plain
}

let data = try await Health().execute(client: client)
```

## Transform vs middleware

| Concern | Where |
|---|---|
| Headers / body tweaks on `URLRequest` | `transformRequest` on ``URLSessionAPIClient`` |
| Retry, logging, auth refresh across adapters | `APIClientMiddleware` in APIClientKit |

## See also

- ``URLSessionAPIClient``
- Core architecture: `Sources/APIClientKit/APIClientKit.docc/Architecture.md`
