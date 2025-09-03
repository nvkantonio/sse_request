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

    final controller = SseSourceController(
      name: 'Name:1',
      sseStreamBuilder: request.sendStreamed,
      onNewConnection: (name) =>
          print('Creating new SSE connection to "$name"'),
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

    final errors = [];

    final subscription = controller.stream.listen((event) {
      dev.log(event.toString());
    }, onError: (e) {
      dev.log(e.toString());
      errors.add(e);
    });

    await Future.delayed(Duration(seconds: 3));
    controller.dispose();

    await Future.delayed(Duration(seconds: 10));
    subscription.cancel();

    expect(errors, isEmpty);
    dev.log('END');
    return;
  });
}
