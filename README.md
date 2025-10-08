# SSE_REQUEST

Simple SSE (Server-Sent Events) consumer.
Built around [dart:http](https://pub.dev/packages/http) [Request](https://pub.dev/documentation/http/latest/http/Request-class.html).

## Features

- Consumes SSE and converts each event into a `Map<String, dynamic>`.
- Configurable and extensible.
- Can be configured to auto-reconnect or perform any action you want on caught exceptions.
- Can be configured to parse each event with ease.

## Getting started

- Add package to pubspec.yaml:

```yaml
dependencies:
  sse_request: ^0.1.1
```

- Import package:

```dart
import 'package:sse_request/sse_request.dart';
```

- Obtain `Stream` from `sseRequestGetStream()`.
- Add a listener to the `Stream`.

## Usage

```dart

import 'dart:developer' as dev;
import 'package:sse_request/sse_request.dart';

void main() async {
  /// Obtain a [Stream] of events.
  ///
  /// SubName is the subscription name, which is used
  /// to distinguish connection events for multiple streams.
  ///
  /// Nothing is send until the first listener is attached.
  final streamGET = sseRequestGetStream(
    uri: Uri.parse('your_uri'),
    subName: 'name:1',
    headers: {'hello': 'world'},
  );

  final streamPOST = sseRequestPostStream(
    uri: Uri.parse('your_uri'),
    subName: 'name:2',
    headers: {'hello': 'world'},
    body: {'hello': 'world'},
  );

  /// Listens to the parsed SSE event stream.
  final subscription = streamGET.listen(
    (event) {
      dev.log(event.toString());
    },
    onError: (e) {
      dev.log('Invalid SSE message: $e');
    },
  );

  // Demonstration delay.
  await Future.delayed(Duration(seconds: 10));
  dev.log('END');

  /// Don't forget to close the [StreamSubscription] to
  /// avoid memory leaks.
  subscription.cancel();
}
```

***For advanced functionality prefer using `SseSourceController` or `SseParsedSourceController<T>`, or even implement `SseSourceControllerBase`.***

---

### Going further

The package consists of two parts:

- Data stream converters.
- Data stream controller `SseSourceController`, which manages connection lifecycle and event handling.

#### Usage of `SseSourceController`

```dart
import 'dart:async';
import 'dart:developer' as dev;
import 'package:sse_request/sse_request.dart';

Future<void> main() async {
  final controller = SseSourceController(
    // This name used to distinguish connection events for multiple streams.
    name: 'Name:1',
    // Specify the builder function for obtaining the event stream.
    sseStreamBuilder: (client) => sseRequestGetSendStreamed(
      uri: Uri.parse('your_api_uri'),
      client: client,
    ),
    // Invoked when a new SSE connection is inbound.
    onNewConnection: (name) => dev.log('Creating new SSE connection to "$name"'),
    // Invoked when the SSE connection is established.
    onConnected: (name) => dev.log('Established SSE connection to "$name"'),
    // Invoked when the SSE connection is closed.
    onCloseConnection: (name, wasConnected) {
      if (wasConnected) {
        dev.log('Closed SSE subscription $name');
      } else {
        dev.log('Closed SSE subscription $name without being opened');
      }
    },
    // Invoked when the stream is cancelled.
    onCancel: (name, wasConnected) {
      if (wasConnected) {
        dev.log('Canceled SSE subscription $name');
      } else {
        dev.log('Canceled SSE subscription $name without being opened');
      }
    },
  );

  // Establish an SSE connection.
  // Nothing is sent until the first listener is attached.
  final subscription = controller.stream.listen((event) {
    dev.log(event.toString());
  }, onError: (e) {
    dev.log(e.toString());
  });

  // Demonstration delay.
  await Future.delayed(Duration(seconds: 10));

  /// Don't forget to close the StreamSubscription
  /// to avoid memory leaks.
  subscription.cancel();

  // `dispose()` or `clear()` methods can be used to force close
  // connection  using controller, where `dispose()` ensures
  // you cannot use the controller again.
  controller.dispose();
}
```

#### Add reconnection

`SseSourceController`'s stream is separate from the SSE stream, so if connection to the server is lost, a new SSE stream can be attached using `connectEventListener()`. This can be handled by `actionOnErrorEvent`;

```dart
import 'dart:async';
import 'dart:developer' as dev;
import 'package:http/http.dart';
import 'package:sse_request/sse_request.dart';

Future<void> main() async {
  // Create a new SSE stream request for each connection attempt
  sseStreamBuilder(Client client) => sseRequestGetSendStreamed(
        uri: Uri.parse('your_api_uri'),
        client: client,
      );

  final controller = SseSourceController(
    name: 'Name:1',
    sseStreamBuilder: sseStreamBuilder,
    // `actionOnErrorEvent` invoked on every error event with
    // controller instance and error itself.
    actionOnErrorEvent: (controller, error, st) async {
      // Implementation of reconnection logic.
      //
      // With the callback of `SseSourceController controller`
      // you can handle how the controller reacts to certain errors.
      try {
        // Cancel current event listener and close http client.
        await controller.clear();

        // Connect new event listener.
        await controller.connectEventListener(sseStreamBuilder);
      } catch (e) {
        // On failed connection retry, you can dispose the controller
        // or retry again after a delay.
        await controller.dispose();
        rethrow;
      }
    },
  );
}
```

#### Parse each event

Use `SseParsedSourceController<T>` instead of `SseSourceController` to set a custom type for the stream and define `eventParser`;

```dart
SseParsedSourceController<String>(
  name: 'Name:1',
  sseStreamBuilder: (client) => sseRequestGetSendStreamed(
    uri: Uri.parse('your_api_uri'),
    client: client,
  ),
  // Invoked on every new event. Expects to return a value of specified type
  // or throw an error, which will call [onErrorEvent], so you don't need to
  // duplicate error handling logic.
  eventParser: (Map<String, dynamic> event) {
    // Implement your parser here.
    try {
      return event['response'];
    } catch (e) {
      // On unhandled exeption will call [onErrorEvent].
      rethrow;
    }
  },
);
```

## Additional info

Known issues:

- Too many data in a single stream response or a short amount of time could be cut off
