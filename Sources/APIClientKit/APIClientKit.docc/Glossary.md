# Glossary

Domain vocabulary for APIClientKit.

## Endpoint

A declarative description of one HTTP call (path, method, task, headers).

## API Client

The transport seam that turns an Endpoint into a Response (`makeRequest`).

## Adapter

A concrete API Client (URLSession, in-memory, server HTTP client). Owns wire types.

## Middleware

A composable intercept around `makeRequest` (auth, retry, logging). Sees raw status codes.

## Response

Transport-agnostic HTTP result: URL, status, headers, body bytes.

## Response Validation

Mapping of non-2xx status codes to `APIClientError`, applied at `Endpoint.execute`, not inside middleware.

## Model Endpoint

An Endpoint that knows how to decode a typed body with a `JSONDecoder`.
