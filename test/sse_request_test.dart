import 'dart:async';
import 'dart:developer' as dev;
import 'package:sse_request/sse_request.dart';
import 'package:test/test.dart';

// @TestOn('vm')
void main() async {
  test('Testing sse chat messages', () async {
    final request = SseRequest.get(uri: Uri.parse('your_uri'));

    final stream = request.getStream('Name:1');

    final subscription = stream.listen((event) {
      try {
        dev.log(event.toString());
      } catch (e) {
        dev.log('Invalid sse message: $e');
        dev.inspect(event);
      }
    });

    expect(stream, neverEmits(throwsA(anything)));

    await Future.delayed(Duration(seconds: 30));
    dev.log('END');
    subscription.cancel();
    return;
  });
}
