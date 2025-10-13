@TestOn('vm')
library;

import 'dart:async';
import 'package:sse_request/sse_request.dart';
import 'package:test/test.dart';

void main() async {
  test('Testing sse chat messages', () {
    expect(() async {
      final request = SseRequest.get(
        uri: Uri.parse('your_api_uri'),
      );

      final stream = request.getStream('Name:1');

      final subscription = stream.listen((event) {
        print(event.toString());
      }, onError: (e) {
        print(e.toString());
        throw e;
      });

      await Future.delayed(Duration(seconds: 10));
      subscription.cancel();

      print('END');
    }(), completes);
  });
}
