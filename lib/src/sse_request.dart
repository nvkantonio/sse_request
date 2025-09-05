import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:http/http.dart';

import '../sse_source_controllers.dart';
import '../sse_transformers.dart';

/// An HTTP request where the entire request body is known in advance.
final class SseRequest extends Request {
  /// Creates an SSE request with the specified method, URI, headers, body,
  /// and encoding.
  ///
  /// {@template sse_request}
  /// - [method] is the request method of [SseRequestType].
  ///
  /// - [uri] is the URL of the SSE endpoint.
  ///
  /// - [headers] is a map of request headers.
  ///
  /// - [body] is an optional request body for POST requests.
  ///
  /// - [encoding] is the preferred encoding to decode the SSE stream.
  ///
  /// Adds next default headers:
  /// ```json
  /// {"Cache-Control" = "no-cache", "Accept" = "text/event-stream"}
  /// ```
  ///
  /// Example:
  /// ```dart
  /// /// Creates an [SseRequest] for a POST request.
  /// final request = SseRequest.post(
  ///   uri: Uri.parse('your_uri'),
  ///   headers: {'hello': 'world'},
  ///   body: {'hello': 'world'},
  /// );
  ///
  /// /// Obtains a [Stream] of events.
  /// /// Nothing is send until the first listener is attached.
  /// final stream = request.getStream('name:1');
  ///
  /// /// Listens to the parsed SSE event stream.
  /// final subscription = stream.listen(
  ///   (event) {
  ///     dev.log(event.toString());
  ///   },
  ///   onError: (e) {
  ///     dev.log('Invalid SSE message: $e');
  ///   },
  /// );
  ///
  /// // Demonstration delay.
  /// await Future.delayed(Duration(seconds: 10));
  ///
  /// /// Don't forget to close the StreamSubscription to avoid memory leaks.
  /// subscription.cancel();
  /// ```
  /// {@endtemplate}
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

  /// Creates an SSE GET request.
  ///
  /// {@macro sse_request}
  SseRequest.get({
    required Uri uri,
    Map<String, String>? headers,
    Encoding? encoding,
  }) : this(method: 'GET', headers: headers, uri: uri, encoding: encoding);

  /// Creates an SSE POST request.
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

  /// Returns a stream of parsed SSE events.
  ///
  /// If you need precise control over the event stream, prefer using
  /// [SseSourceController] or implementing [SseSourceControllerBase].
  ///
  /// [subName] is the subscription name.
  /// [useBroadCast] determines if the stream is broadcast.
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

  /// Sends the SSE request and and transforms [ByteStream] to
  /// [Map<String, dynamic>] for every event.
  ///
  /// [client] is an optional HTTP client to use for the request.
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
