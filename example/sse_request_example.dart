// Example usage of SseRequest.
// Demonstrates how to use SseRequest for both POST and GET requests.

// ignore_for_file: unused_local_variable

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
  /// Does not connect to the API until the first listener is attached.
  final stream = getRequest.getStream('name:1');

  /// Listens to the SSE event stream parsed as regular JSON {event_name: event_data}.
  final subscription = stream.listen(
    (event) {
      dev.log(event.toString());
    },
    onError: (e) {
      dev.log('Invalid SSE message: $e');
    },
  );

  await Future.delayed(Duration(seconds: 10));
  dev.log('END');

  /// Don't forget to close the StreamSubscription to avoid memory leaks.
  subscription.cancel();
}
