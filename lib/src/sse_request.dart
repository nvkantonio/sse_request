import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:http/http.dart';

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
class SseRequest extends Request {
  /// {@macro sse_request}
  SseRequest({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Encoding? encoding,
  }) : super(method, uri) {
    headers?.forEach((key, value) {
      super.headers[key] = value;
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
  /// Close [StreamSubscribtion] on done to prevent memory leaks.
  ///
  /// This automatically initializes and closes [Client].
  Stream<Map<String, dynamic>> getStream(
    String subName, [
    bool useBroadCast = false,
  ]) {
    final client = Client();

    final StreamController<Map<String, dynamic>> streamController =
        useBroadCast ? StreamController.broadcast() : StreamController();

    streamController
      ..onListen = () async {
        dev.log("Opened SSE subscription \"$subName\"");
        try {
          streamController.addStream(await _sendStreamed(client));
        } catch (e) {
          client.close();
          streamController.addError(SseConnectionExeption(
            message: 'Could not connect to SSE: $e',
            originalExeption: e,
          ));
          streamController.close();
        }
      }
      ..onCancel = () {
        dev.log("Closed SSE subscription $subName");
        client.close();
        streamController.close();
      };

    return streamController.stream;
  }

  Future<Stream<Map<String, dynamic>>> _sendStreamed(Client client) async {
    try {
      final streamedResponse = await client.send(this);
      dev.log("Connected to sse");

      final transformedResponseStream = streamedResponse.stream
          .transform(encoding.decoder)
          .transform(sseStreamSplitter)
          .transform(sseStreamParser);

      return transformedResponseStream;

      // TODO(nvkantonio) rework exceptions
    } on ClientException {
      client.close();
      rethrow;
    } on ByteStreamSplitException {
      rethrow;
    } on SseParseException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}
