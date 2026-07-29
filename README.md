# APIClientKit

Cross-platform Swift 6 HTTP client primitives (Endpoint, middleware, typed errors) plus an optional URLSession adapter product.

[![Swift](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FsGerli%2FAPIClientKit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/sGerli/APIClientKit)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FsGerli%2FAPIClientKit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/sGerli/APIClientKit)

## Products

- **APIClientKit** — core seams (`APIClientProtocol`, `Endpoint`, middleware, `InMemoryAPIClient`). Uses `FoundationEssentials` when available.
- **APIClientKitURLSession** — `URLSessionAPIClient` adapter. Depends on `FoundationNetworking` on Linux.

## Documentation

- DocC catalogs ship in-tree under each target’s `*.docc` bundle.
- Swift Package Index hosts generated docs once the package is indexed (see `.spi.yml`).
- Agent-oriented pointers: [`AGENTS.md`](AGENTS.md).
- CI: [`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs `swift test` on Swift 6.3+ (Linux, Windows, macOS, Android SDK build).

```bash
swift package generate-documentation --target APIClientKit
swift package generate-documentation --target APIClientKitURLSession
```

## Quick start

```swift
import APIClientKit
import APIClientKitURLSession

struct Health: Endpoint {
    let path = "/health"
    let method = Method.get
    let task = EndpointTask.plain
}

let client = URLSessionAPIClient(baseURL: URL(string: "https://example.com")!)
let data = try await Health().execute(client: client)
```
