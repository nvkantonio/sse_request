// Example usage of SseSourceController reconnection.
// Demonstrates how to handle lost connections and automatically
//reconnect using SseSourceController and SseRequest.

import 'dart:async';
import 'dart:developer' as dev;
import 'package:http/http.dart';
import 'package:sse_request/sse_request.dart';

Future<void> main() async {
  // Create a new SSE stream request for each connection attempt, as a single request instance cannot be reused.
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
      // Implement of reconnection logic
      //
      // With the callback of `SseSourceController controller`,
      // you can handle how the controller reacts to certain errors.
      try {
        print(error.toString());

        // Cancel current event listener and close http client
        await controller.clear();

        // Connect new event listener
        await controller.connectEventListener(sseStreamBuilder);
      } catch (e) {
        // On unsuccessful connection retry, you can dispose the controller
        // or retry again after a delay.
        await controller.dispose();
        rethrow;
      }
    },
  );

  // Listen to SSE events and errors
  final subscription = controller.stream.listen((event) {
    dev.log(event.toString());
  }, onError: (e) {
    dev.log('Got exception event $e');
  });

  // Simulate lost connection after delay
  await Future.delayed(Duration(seconds: 3));
  print('Closing client');

  // ignore: invalid_use_of_protected_member
  controller.closeClient();

  // Wait for events for 10 more seconds
  await Future.delayed(Duration(seconds: 10));
  subscription.cancel();

  print('END');
}
