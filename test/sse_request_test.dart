@TestOn('vm')
library;

import 'dart:async';
import 'dart:developer' as dev;
import 'package:sse_request/sse_request.dart';
import 'package:test/test.dart';

void main() async {
  test('Testing sse chat messages', () async {
    final request = SseRequest.get(
      uri: Uri.parse('your_api_uri'),
    );

    final stream = request.getStream('Name:1');

    final errors = [];

    final subscription = stream.listen((event) {
      dev.log(event.toString());
    }, onError: (e) {
      dev.log(e.toString());
      errors.add(e);
    });

    await Future.delayed(Duration(seconds: 10));
    subscription.cancel();

    expect(errors, isEmpty);

    dev.log('END');
    return;
  });
}
