# Architecture

APIClientKit separates **what to call** from **how it is transported**.

## Core types

| Term | Meaning |
|---|---|
| Endpoint | Declarative description of one HTTP call |
| API Client | Transport seam: ``APIClientProtocol/makeRequest(endpoint:)`` |
| Adapter | Concrete client (URLSession, in-memory, …); owns wire types |
| Middleware | Intercept around `makeRequest`; sees raw status codes |
| Response | Transport-agnostic result (URL, status, headers, body) |
| Response validation | Maps non-2xx into ``APIClientError`` at `Endpoint.execute` |

Canonical glossary: <doc:Glossary>.

## Seams

```
Endpoint.execute ──► APIClientProtocol.execute (middleware fold)
                              │
                              ▼
                     makeRequest(endpoint)   ← adapter-owned
                              │
                              ▼
                          Response
                              │
              Endpoint.execute applies ResponseValidation
```

Wire types such as `URLRequest` / `HTTPURLResponse` stay inside adapters. The core ``Response`` intentionally omits Foundation networking objects so Essentials-only consumers stay lean.

## Foundation policy

Prefer `FoundationEssentials` (exported from this module). Pull `APIClientKitURLSession` only when you need URLSession.

## See also

- <doc:GettingStarted>
- ``APIClientProtocol``
- ``InMemoryAPIClient``
