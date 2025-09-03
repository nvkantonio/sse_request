import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:http/http.dart';

import '../sse_source_controllers.dart';
import '../sse_transformers.dart';

/// {@template sse_request}
/// An HTTP SSE request where the entire request body is known in advance.
///
/// For precise control, prefer [sse_trasformers.dart] included library instead.
///
/// [method] is the request method of [SseRequestType].
/// [url] is the URL of the SSE endpoint.
/// [header] is a map of request headers.
/// [body] is an optional request body for POST requests.
/// [encoding] is preferred encoding to decode SSE stream.
///
/// example:
/// ```dart
////// Create [SseRequest] using [SseRequest.get] or [SseRequest.post]
///  final request = SseRequest.post(
///    uri: Uri.parse('your_uri'),
///    headers: {'hello': 'world'},
///    body: {'hello': 'world'},
///  );
///
///  /// Obtain [Stream] of events
///  /// Doesn't connect to api until first listener
///  final stream = request.getStream('name:1');
///
///  /// Listen to SSE event stream parsed as regular json {event_name: event_data}
///  final subscription = stream.listen((event) {
///    dev.log(event.toString());
///  }, onError: (e) {
///    dev.log('Invalid sse message: $e');
///  });
///
///  await Future.delayed(Duration(seconds: 30));
///  dev.log('END');
///
///  /// Dont forget to close StreamSubscription
///  subscription.cancel();
/// ```
/// {@endtemplate}
final class SseRequest extends Request {
  /// {@macro sse_request}
  SseRequest({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Encoding? encoding,
  }) : super(method, uri) {
    super.headers.addAll({
      'Cache-Control': 'no-cache',
      'Accept': 'text/event-stream',
      if (headers != null)
        for (final e in headers.entries) e.key: e.value
    });

    super.encoding = encoding ?? utf8;

    if (body != null) super.body = jsonEncode(body);
  }

  /// Simply adds GET method and removes unnecessary body.
  ///
  /// {@macro sse_request}
  SseRequest.get({
    required Uri uri,
    Map<String, String>? headers,
    Encoding? encoding,
  }) : this(method: 'GET', headers: headers, uri: uri, encoding: encoding);

  /// Simply adds POST method.
  ///
  /// {@macro sse_request}
  SseRequest.post({
    required Uri uri,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Encoding? encoding,
  }) : this(
          method: 'POST',
          headers: headers,
          uri: uri,
          body: body,
          encoding: encoding,
        );

  /// Sends this request.
  ///
  /// Doesn't connect to api until first listener.
  /// Close [StreamSubscription] on done to prevent memory leaks.
  ///
  /// This automatically initializes and closes [Client].
  Stream<Map<String, dynamic>> getStream(
    String subName, [
    bool useBroadCast = false,
  ]) {
    final controller = SseSourceController(
      isBroadCast: useBroadCast,
      name: subName,
      sseStreamBuilder: sendStreamed,
      onNewConnection: (name) =>
          dev.log('Creating new SSE connection to "$name"'),
      onConnected: (name) => dev.log('Established SSE connection to "$name"'),
      onCloseConnection: (name, wasConnected) {
        if (wasConnected) {
          dev.log('Closed SSE subscription $name');
        } else {
          dev.log('Closed SSE subscription $name without being opened');
        }
      },
    );

    return controller.stream;
  }

  Future<Stream<Map<String, dynamic>>> sendStreamed(Client? client) async {
    try {
      final streamedResponse =
          await (client != null ? client.send(this) : send());

      final transformedResponseStream = streamedResponse.stream
          .transform(encoding.decoder)
          .transform(sseStreamSplitter)
          .transform(sseStreamParser);

      return transformedResponseStream;
    } catch (e) {
      rethrow;
    }
  }
}
