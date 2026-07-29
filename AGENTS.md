# AGENTS.md

Swift 6 package: declarative HTTP API client core (`APIClientKit`) plus optional URLSession adapter (`APIClientKitURLSession`).

## Before you change behavior

Read the DocC catalog — it is the canonical product documentation. Prefer catalog articles over inventing new seams.

| Topic | DocC source |
|---|---|
| Overview / topics | `Sources/APIClientKit/APIClientKit.docc/APIClientKit.md` |
| Getting started | `Sources/APIClientKit/APIClientKit.docc/GettingStarted.md` |
| Architecture & seams | `Sources/APIClientKit/APIClientKit.docc/Architecture.md` |
| Glossary | `Sources/APIClientKit/APIClientKit.docc/Glossary.md` |
| Middleware | `Sources/APIClientKit/APIClientKit.docc/MiddlewareGuide.md` |
| Status → errors | `Sources/APIClientKit/APIClientKit.docc/ResponseValidationGuide.md` |
| URLSession adapter | `Sources/APIClientKitURLSession/APIClientKitURLSession.docc/UsingURLSession.md` |
| URLSession module | `Sources/APIClientKitURLSession/APIClientKitURLSession.docc/APIClientKitURLSession.md` |

Domain vocabulary: `Sources/APIClientKit/APIClientKit.docc/Glossary.md`.

Hosted docs (after SPI indexes the package): 
`https://swiftpackageindex.com/sGerli/APIClientKit/documentation/apiclientkit`

## Commands

```bash
swift build
swift test
swift package generate-documentation --target APIClientKit
swift package generate-documentation --target APIClientKitURLSession
```

CI: `.github/workflows/ci.yml` (Swift 6.3+ via `swiftlang/github-workflows`).

Swift Package Index config: `.spi.yml` (documents both targets; landing target is `APIClientKit`).

## Non‑negotiables

1. **Core stays networking-free.** No `URLSession` / `FoundationNetworking` in `APIClientKit`. Wire types belong in adapters.
2. **Client seam is `makeRequest(endpoint:) → Response`.** Do not put transport `RequestType` / `transformRequest` on `APIClientProtocol`.
3. **Middleware sees raw status codes.** Validation runs only via `ResponseValidation` inside `Endpoint.execute*`, not inside `APIClientProtocol.execute`.
4. **Prefer `FoundationEssentials`.** Full `Foundation` / `JSONSerialization` are not allowed in core.
5. **Keep `Response` transport-agnostic.** Do not reintroduce untyped `Any` underlying responses on the core type without updating DocC.
6. **Products:** public HTTP types in `APIClientKit`; `URLSessionAPIClient` only in `APIClientKitURLSession`.

## Done when

- `swift test` passes
- Public API changes update DocC articles under `*.docc/`
- New domain terms land in `Sources/APIClientKit/APIClientKit.docc/Glossary.md`
