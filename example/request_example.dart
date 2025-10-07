// Example usage of SseRequest.
// Demonstrates how to use SseRequest for both POST and GET requests.

// ignore_for_file: unused_local_variable

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
