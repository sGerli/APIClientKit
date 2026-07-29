# ``APIClientKit``

Cross-platform Swift 6 HTTP client primitives: declarative endpoints, middleware, typed errors, and transport adapters.

Use the `APIClientKitURLSession` product when you want a URLSession-backed adapter. Keep this core module free of networking so Linux / Android / server consumers can depend on Essentials-sized binaries.

## Products

- ``APIClientProtocol`` — transport seam (`makeRequest` → ``Response``)
- ``Endpoint`` / ``ModelEndpoint`` / ``VoidEndpoint`` — declarative call descriptions
- ``APIClientMiddleware`` / ``Next`` — composable request/response interception
- ``ResponseValidation`` — HTTP status → ``APIClientError`` mapping
- ``InMemoryAPIClient`` — in-process adapter for tests

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:Architecture>
- <doc:Glossary>

### Building requests

- ``Endpoint``
- ``EndpointTask``
- ``JSONValue``
- ``Method``

### Executing requests

- ``APIClientProtocol``
- ``Endpoint``
- ``InMemoryAPIClient``
- <doc:GettingStarted>

### Middleware

- <doc:MiddlewareGuide>
- ``APIClientMiddleware``
- ``Next``
- ``APIClientDebugLoggingMiddleware``

### Responses and errors

- <doc:ResponseValidationGuide>
- ``Response``
- ``ResponseValidation``
- ``APIClientError``
