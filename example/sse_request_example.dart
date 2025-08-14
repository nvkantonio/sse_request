import 'dart:developer' as dev;
import 'package:sse_request/sse_request.dart';

void main() async {
  await post();
}

Future<void> post() async {
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

Future<void> get() async {
  final request = SseRequest.get(
    uri: Uri.parse('your_uri'),
    headers: {'hello': 'world'},
  );

  final stream = request.getStream('name:1');

  final subscription = stream.listen((event) {
    try {
      dev.log(event.toString());
    } catch (e) {
      dev.log('Invalid sse message: $e');
    }
  });

  await Future.delayed(Duration(seconds: 30));
  dev.log('END');
  subscription.cancel();
}
