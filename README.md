# SSE_REQUEST

Simple SSE (Server Sent Events) consumer.

## Features

- Consumes Server Sent Events from api, transforms it to simple `Map<String, dynamic>` for each event

## Getting started

- Add package to pubspec.yaml:
```yaml
sse_request:
    git:
      url: https://github.com/nvkantonio/sse_request
```

- Import package:
```dart
import 'package:sse_request/sse_request.dart';
```

- Create `SseRequest()` object and call `.getStream()`
- Add listener to Stream


## Usage

```dart
import 'dart:developer' as dev;
import 'package:sse_request/sse_request.dart';

void main() async {
  /// Create [SseRequest] using [SseRequest.get] or [SseRequest.post]
  final request = SseRequest.post(
    uri: Uri.parse('your_uri'),
    headers: {'hello': 'world'},
    body: {'hello': 'world'},
  );

  /// Obtain [Stream] of events
  /// Doesn't connect to api until first listener
  final stream = request.getStream('name:1');

  /// Listen to SSE event stream parsed as regular json {event_name: event_data}
  final subscription = stream.listen((event) {
    dev.log(event.toString());
  }, onError: (e) {
    dev.log('Invalid sse message: $e');
  });

  await Future.delayed(Duration(seconds: 30));
  dev.log('END');

  /// Dont forget to close StreamSubscription
  subscription.cancel();
}
```

## Additional info

This package doesn't work for web.

This package doesn't support bidirectional protocol implementation. In that case prefer using [official sse package](https://pub.dev/packages/sse) instead.