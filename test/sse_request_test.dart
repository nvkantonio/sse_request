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
      dev.log(event.toString());
    }, onError: (e) {
      dev.log('Invalid sse message: $e');
      dev.inspect(e);
    });

    expect(stream, neverEmits(throwsA(anything)));

    await Future.delayed(Duration(seconds: 30));
    dev.log('END');
    subscription.cancel();
    return;
  });
}
