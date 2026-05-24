## 0.3.0

- Update: StreamSourceController implements StreamController.
- Breaking change:
  - Fix class name typos

## 0.2.1

- Added tags to pubspec.yaml
- Tests refactor

## 0.2.0

- New:
  - Obtain handled stream and event stream straight from request shorthand methods
  - Isolated sse request handlers to be used within any `BaseRequest`
  - Added equality checks to StreamSourceController and SseSourceControllerBase
- Fix: Type annotations
- Example: Updated using request shorthand
- Test: Updated using request shorthand
- Docs:
  - Updated README
  - Added documentation to shorthand methods
  - Updated code documentation

## 0.1.2

- Docs: Documentation improvement

## 0.1.1

- Breaking change: `SseSourceControllerBase` now have generic type
- New: added `SseParsedSourceController`, which allows for configuration of reconnection logic and parsing of each event into a specified object type.

## 0.1.0

- New: `SseSourceController`, which manages connection lifecycle and event handling, and providing precise control over events. This change also offers significantly better extensibility.
- Improvement: `SseRequest`'s `getStream()` now uses `SseSourceController`
- New: Default request headers for `SseRequest`.
- Docs: Improved documentation and examples.

## 0.0.3

- Rework: `SseRequest` now decodes SSE event stream first, then splits it to events
- Fix: stream parser invalid exceptions

## 0.0.2

- Breaking changes: `SseRequest` exposes `Stream` instead of `SteamController`.
- Improvement: `SseRequest` now automatically handles listeners and closes events;

## 0.0.1

- Initial version
