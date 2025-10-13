@TestOn('vm')
library;

import 'dart:async';
import 'package:sse_request/sse_request.dart';
import 'package:test/test.dart';

void main() async {
  test('Testing sse chat messages', () {
    expect(() async {
      final controller = SseSourceController(
        name: 'Name:1',
        sseStreamBuilder: (client) => sseRequestGetSendStreamed(
          uri: Uri.parse('your_api_uri'),
          client: client,
        ),
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

      final subscription = controller.stream.listen((event) {
        print(event.toString());
      }, onError: (e) {
        print(e.toString());
        throw e;
      });

      await Future.delayed(Duration(seconds: 3));
      controller.dispose();

      await Future.delayed(Duration(seconds: 10));
      subscription.cancel();

      print('END');
    }(), completes);
  });
}
