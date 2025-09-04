@TestOn('vm')
@Timeout(Duration(minutes: 1))
library;

import 'dart:async';
import 'dart:developer' as dev;
import 'package:http/http.dart';
import 'package:sse_request/sse_request.dart';
import 'package:test/test.dart';

void main() async {
  test('Testing sse chat messages', () async {
    sseStreamBuilder(Client client) {
      return SseRequest.get(
        uri: Uri.parse('your_api_uri'),
      ).sendStreamed(client);
    }

    final controller = SseSourceController(
      name: 'Name:1',
      sseStreamBuilder: sseStreamBuilder,
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
      actionOnErrorEvent: (controller, error, st) async {
        try {
          print(error.toString());
          print('Clear controller');
          await controller.clear();
          await controller.connectEventListener(sseStreamBuilder);
        } catch (e) {
          await controller.dispose();
          rethrow;
        }
      },
    );

    final errors = [];

    final subscription = controller.stream.listen((event) {
      dev.log(event.toString());
    }, onError: (e) {
      dev.log('Got exeption event $e');
      if (e is! ClientException) {
        errors.add(e);
      }
    });

    await Future.delayed(Duration(seconds: 3));
    print('Closing client');
    // Simulate lost connection
    // ignore: invalid_use_of_protected_member
    controller.closeClient();

    await Future.delayed(Duration(seconds: 10));
    subscription.cancel();

    expect(errors, isEmpty);

    print('END');
    return;
  });
}
