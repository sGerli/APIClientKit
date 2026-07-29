# Middleware Guide

Conform to ``APIClientMiddleware`` and return the array from ``APIClientProtocol/middlewares``.

## Call order

Given `middlewares = [A, B, C]`:

```
A.intercept → B.intercept → C.intercept → makeRequest
```

``Next/respond(to:)`` may be called more than once (retry). Status codes are **not** validated inside the chain.

## Example

```swift
struct UserAgentMiddleware: APIClientMiddleware {
    func intercept(
        endpoint: any Endpoint,
        next: Next
    ) async throws(APIClientError) -> Response {
        // Inspect / substitute endpoint, then forward:
        try await next.respond(to: endpoint)
    }
}
```

Wire-level header mutation for URLSession belongs on `URLSessionAPIClient.transformRequest` in the URLSession product — not on the core client protocol.

## Debug logging

``APIClientDebugLoggingMiddleware`` correlates `phase=start` (from the adapter after the wire request is built) with `phase=end` / `phase=fail`. Pair it with `APIClientDebugLog.logWireRequestStartIfPresent` inside custom adapters.

## See also

- ``APIClientMiddleware``
- ``Next``
- ``APIClientDebugLoggingMiddleware``
