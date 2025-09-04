## 0.1.0

- New: Now uses `SseSourceController`, which manages connection lifecycle and event handling, and providing precise control over events. This change also offers significantly better extensibility.
- Added default request headers for `SseRequest`.
- Improved documentation and examples.

## 0.0.3

- Now decodes stream response then split it to events
- Fix stream parser invalid exeptions
- Fix sse_request_test

## 0.0.2

- Breaking changes
- SSE request exposes Stream instead of SteamController and automatically handle listeners and close events

## 0.0.1

- Initial version
