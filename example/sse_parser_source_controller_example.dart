// Example usage of SseParsedSourceController.
// Demonstrates how to parse events with
// SseParsedSourceController and SseRequest.

import 'dart:async';
import 'dart:developer' as dev;
import 'package:sse_request/sse_request.dart';

Future<void> main() async {
  // Create an SSE GET request
  final request = SseRequest.get(
    uri: Uri.parse('your_api_uri'),
  );

  /// Use [SseParsedSourceController<T>] instead of
  /// [SseSourceController] to set a custom type for the stream.
  final controller = SseParsedSourceController<String>(
    // The name used to distinguish connection events for multiple streams.
    name: 'Name:1',
    // Specify the builder function for obtaining the event stream.
    sseStreamBuilder: request.sendStreamed,
    // Invoked on every new event. Expects to return a value of specified type
    // or throw an error, which will call [onErrorEvent], so you don't need to
    // duplicate error handling logic.
    eventParser: (Map<String, dynamic> event) {
      // Implement your parser here.
      try {
        return event.values.first;
      } catch (e) {
        // On unhandled exeption will call [onErrorEvent].
        rethrow;
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
