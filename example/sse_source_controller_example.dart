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
    name: 'Name:1',
    sseStreamBuilder: request.sendStreamed,
    onNewConnection: (name) => print('Creating new SSE connection to "$name"'),
    onConnected: (name) => print('Established SSE connection to "$name"'),
    onCloseConnection: (name, wasConnected) {
      if (wasConnected) {
        print('Closed SSE subscription $name');
      } else {
        print('Closed SSE subscription $name without being opened');
      }
    },
    onCancel: (name, wasConnected) {
      if (wasConnected) {
        print('Canceled SSE subscription $name');
      } else {
        print('Canceled SSE subscription $name without being opened');
      }
    },
  );

  final subscription = controller.stream.listen((event) {
    dev.log(event.toString());
  }, onError: (e) {
    dev.log(e.toString());
  });

  // Wait for events for 10 seconds
  await Future.delayed(Duration(seconds: 10));
  subscription.cancel();
  print('END');
}
