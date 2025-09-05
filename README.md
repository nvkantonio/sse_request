# SSE_REQUEST

Simple SSE (Server-Sent Events) consumer.
Built around [dart:http](https://pub.dev/packages/http) [Request](https://pub.dev/documentation/http/latest/http/Request-class.html).

## Features

- Consumes SSE and converts each event into a `Map<String, dynamic>`.
- Can be configured to autoreconnect or do whatever you want on caught exeption.

## Getting started

- Add package to pubspec.yaml:
```yaml
dependencies:
  sse_request: ^0.1.0
```

- Import package:
```dart
import 'package:sse_request/sse_request.dart';
```

- Create an `SseRequest()` object and call `.getStream()`.
- Add a listener to the Stream.

## Usage

```dart
import 'dart:developer' as dev;
import 'package:sse_request/sse_request.dart';

void main() async {
  /// Create an [SseRequest] for a GET request.
  final getRequest = SseRequest.get(
    uri: Uri.parse('your_uri'),
    headers: {'hello': 'world'},
  );

  /// Create an [SseRequest] for a POST request.
  final postRequest = SseRequest.post(
    uri: Uri.parse('your_uri'),
    headers: {'hello': 'world'},
    body: {'hello': 'world'},
  );

  /// Obtains a [Stream] of events.
  /// Nothing is send until the first listener is attached.
  final stream = getRequest.getStream('name:1');

  /// Listens to the parsed SSE event stream.
  final subscription = stream.listen(
    (event) {
      dev.log(event.toString());
    },
    onError: (e) {
      dev.log('Invalid SSE message: $e');
    },
  );

  // Demonstration delay.
  await Future.delayed(Duration(seconds: 10));

  /// Don't forget to close the StreamSubscription to avoid memory leaks.
  subscription.cancel();
}
```

***For advanced functionality prefer using `SseSourceController` or implementing `SseSourceControllerBase`.***

---

### Going further

#### Usage of `SseSourceController`

```dart
import 'dart:async';
import 'dart:developer' as dev;
import 'package:sse_request/sse_request.dart';

Future<void> main() async {
  // Create an SSE GET request.
  final request = SseRequest.get(
    uri: Uri.parse('your_api_uri'),
  );

  final controller = SseSourceController(
    // The name used to distinguish connection events for multiple streams.
    name: 'Name:1',
    // Specify the builder function for obtaining the event stream.
    sseStreamBuilder: request.sendStreamed,
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
  // Nothing is sent until this happens.
  final subscription = controller.stream.listen((event) {
    dev.log(event.toString());
  }, onError: (e) {
    dev.log(e.toString());
  });

  // Demonstration delay.
  await Future.delayed(Duration(seconds: 10));

  /// Don't forget to close the StreamSubscription to avoid memory leaks.
  subscription.cancel();

  // `dispose()` or `clear()` methods can be used to force close connection
  // using controller, where `dispose()` ensures you cannot use
  // the controller again.
  controller.dispose();
}
```

##### Add reconnection

`SseSourceController`'s stream is separate from the SSE stream, so if connection to the server is lost, a new SSE stream can be attached using `connectEventListener()`.

```dart
import 'dart:async';
import 'dart:developer' as dev;
import 'package:http/http.dart';
import 'package:sse_request/sse_request.dart';

Future<void> main() async {
  // Create a new SSE stream request for each connection attempt,
  // as a single request instance cannot be reused.
  sseStreamBuilder(Client client) {
    return SseRequest.get(
      uri: Uri.parse('your_api_uri'),
    ).sendStreamed(client);
  }

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

  final subscription = controller.stream.listen((event) {
    dev.log(event.toString());
  }, onError: (e) {
    dev.log('Got exception event $e');
  });
}
```

#### Some theory

The package consists of two parts:
- Data stream converters.
- Data stream controller `SseSourceController`. Manages connection lifecycle and event handling.

To connect to a data stream, package use `BaseRequest`'s `send()` from the `dart:http` library, which returns a `StreamedResponse`. Instead of waiting for the entire response, you can access `streamedResponse.stream` to receive data as it arrives. This stream provides raw bytes (`ByteData`), which should be decoded and parsed into usable events.

Example of creating a custom StreamedResponse converter:

```dart
import 'package:http/http.dart' as http;
import 'package:sse_request/sse_transformers.dart';

Future<Stream> getStream(http.BaseRequest request) async {
  http.StreamedResponse response = await request.send();

  http.ByteStream byteStream = response.stream;

  Stream<Map<String, dynamic>> convertedSseStream = byteStream
      .transform(encoding.decoder)
      .transform(sseStreamSplitter)
      .transform(sseStreamParser);

  return convertedSseStream;
}
```

`SseRequest` is just a wrapper around `http.Request`, so you can use any method to obtain a data stream and pass it to `SseSourceController`. This is exactly what `SseRequest` does in its `getStream()` method.

## Additional info

This package does not work for web.

This package does not support bidirectional protocol implementation. In that case, consider using the [official sse package](https://pub.dev/packages/sse) instead.

Known issues:
- Too many events in a single stream response could be cut off (probably a length limiter in the dart:http package)