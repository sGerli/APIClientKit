# Response Validation Guide

``ResponseValidation`` is the single place that maps HTTP status codes to ``APIClientError``.

## When it runs

- **Does run:** `Endpoint.execute(client:)`, `ModelEndpoint.execute(client:)`, `VoidEndpoint.execute(client:)`
- **Does not run:** `Endpoint.executeRaw(client:)`, `APIClientProtocol.execute(endpoint:)`, middleware `next.respond`

## Status mapping

| Status | Error |
|---|---|
| 400 | `badRequest` |
| 401 | `unauthorized` |
| 403 | `forbidden` |
| 404 | `notFound` |
| 422 | `unprocessableEntity` |
| 429 | `rateLimitExceeded` (includes `Response` + parsed `retry-after`) |
| 5xx | `serverError` |
| other non-2xx | `unknownStatusCode` |

## See also

- ``ResponseValidation``
- ``Response``
- ``APIClientError``
