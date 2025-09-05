// Example usage of SseSourceController.
// Demonstrates how to connect, listen, and handle events/errors using SseSourceController and SseRequest.

import 'dart:async';
import 'dart:developer' as dev;
import 'package:sse_request/sse_request.dart';

Future<void> main() async {
  // Create an SSE GET request
  final request = SseRequest.get(
    uri: Uri.parse('your_api_uri'),
  );

  final controller = SseSourceController(
    // The name used to distinguish connection events for multiple streams.
    name: 'Name:1',
    // Specify the builder function for obtaining the event stream.
    sseStreamBuilder: request.sendStreamed,
    // Invoked when a new SSE connection is inbound.
    onNewConnection: (name) => print('Creating new SSE connection to "$name"'),
    // Invoked when the SSE connection is established.
    onConnected: (name) => print('Established SSE connection to "$name"'),
    // Invoked when the SSE connection is closed.
    onCloseConnection: (name, wasConnected) {
      if (wasConnected) {
        print('Closed SSE subscription $name');
      } else {
        print('Closed SSE subscription $name without being opened');
      }
    },
    // Invoked when the stream is cancelled.
    onCancel: (name, wasConnected) {
      if (wasConnected) {
        print('Canceled SSE subscription $name');
      } else {
        print('Canceled SSE subscription $name without being opened');
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
  print('END');

  /// Don't forget to close the StreamSubscription to avoid memory leaks.
  subscription.cancel();

  // `dispose()` or `clear()` methods can be used to force close connection
  // using controller, where `dispose()` ensures you cannot use
  // the controller again.
  controller.dispose();
}
