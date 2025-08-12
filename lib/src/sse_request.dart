import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:http/http.dart';

import '../sse_transformers.dart';

typedef SseResposeStreamController = StreamController<Map<String, dynamic>>;

/// {@template sse_request}
/// An HTTP SSE request where the entire request body is known in advance.
///
/// For precise control, prefer import and use [sse_trasformers.dart] instead.
///
/// [method] is the request method of [SseRequestType].
/// [url] is the URL of the SSE endpoint.
/// [header] is a map of request headers.
/// [body] is an optional request body for POST requests.
/// [encoding] is preferred encoding to decode SSE stream.
///
/// example:
/// ```dart
///  /// Create [SseRequest] using [SseRequest.get] or [SseRequest.post]
///  final request = SseRequest.post(
///    uri: Uri.parse('your_uri'),
///    headers: {'hello': 'world'},
///    body: {'hello': 'world'},
///  );
///
///  /// Send request with named connection to obtain [StreamController]
///  final streamController = await request.sendStreamed('name:1');
///
///  /// Listen to SSE event stream parsed as regular json {event_name: event_data}
///  final subscription = streamController.stream.listen((event) {
///    try {
///      dev.log(event.toString());
///    } catch (e) {
///      dev.log('Invalid sse message: $e');
///    }
///  });
///
///  await Future.delayed(Duration(seconds: 30));
///  dev.log('END');
///
///  /// Dont forget to close StreamSubscription and SteamController
///  subscription.cancel();
///
///  /// Closing [SteamController] ensures sending disconnect event to api server
///  streamController.close();
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
  /// Keep in mind this method doesn't automatically closes sse connection, although http [Client] will.
  /// Close connection: `(await SseRequest.sendStreamed('test')).close()`.
  ///
  /// This automatically initializes a new [Client].
  Future<SseResposeStreamController> sendStreamed(
    String subName, [
    bool useBroadCast = false,
  ]) async {
    final client = Client();
    try {
      final streamedResponse = await client.send(this);
      dev.log("Connected to sse");

      final transformedResponseStream = streamedResponse.stream
          .transform(sseStreamSplitter)
          .transform(encoding.decoder)
          .transform(sseStreamParser);

      final StreamController<Map<String, dynamic>> streamController =
          useBroadCast ? StreamController.broadcast() : StreamController();

      streamController
        ..onListen = () {
          dev.log("Opened sse subscription \"$subName\"");
        }
        ..onCancel = () {
          client.close();
          dev.log("Closed sse subscription $subName");
        }
        ..addStream(transformedResponseStream);

      return streamController;

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
