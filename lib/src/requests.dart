import 'dart:convert';
import 'package:http/http.dart';
import 'package:sse_request/sse_request.dart';

/// Creates an SSE GET request with the specified URI, headers  and encoding.
///
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
/// {@template sse_request_requests}
/// Adds next default headers:
/// ```json
/// {"Cache-Control" = "no-cache", "Accept" = "text/event-stream"}
/// ```
///
/// Example:
/// ```dart
/// /// Obtain a [Stream] of events.
/// /// SubName is the subscription name, which is used
/// /// to distinguish connection events for multiple streams.
/// ///
/// /// Nothing is send until the first listener is attached.
/// final streamGET = sseRequestGetStream(
///   uri: Uri.parse('your_uri'),
///   subName: 'name:1',
///   headers: {'hello': 'world'},
/// );
///
/// final streamPOST = sseRequestPostStream(
///   uri: Uri.parse('your_uri'),
///   subName: 'name:2',
///   headers: {'hello': 'world'},
///   body: {'hello': 'world'},
/// );
///
/// /// Listens to the parsed SSE event stream.
/// final subscription = streamGET.listen(
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
/// dev.log('END');
///
/// /// Don't forget to close the [StreamSubscription] to
/// /// avoid memory leaks.
/// subscription.cancel();
/// ```
/// {@endtemplate}
///
Stream<Map<String, dynamic>> sseRequestGetStream({
  required Uri uri,
  required String subName,
  Map<String, String>? headers,
  Encoding? encoding,
}) {
  return SseRequest.get(
    uri: uri,
    headers: headers,
    encoding: encoding,
  ).getStream(subName);
}

/// Sends the GET request with the specified URI, headers, body,
/// and encoding.
///
/// {@macro sse_request_requests}
///
Stream<Map<String, dynamic>> sseRequestPostStream({
  required Uri uri,
  required String subName,
  Map<String, String>? headers,
  Map<String, dynamic>? body,
  Encoding? encoding,
}) {
  return SseRequest.post(
    uri: uri,
    headers: headers,
    encoding: encoding,
    body: body,
  ).getStream(subName);
}

/// Sends the GET request with the specified URI, headers, and encoding.
/// Transforms [ByteStream] to [Map<String, dynamic>] for every event.
Future<Stream<Map<String, dynamic>>> sseRequestGetSendStreamed({
  required Uri uri,
  Client? client,
  Map<String, String>? headers,
  Encoding? encoding,
}) {
  return SseRequest.get(
    uri: uri,
    headers: headers,
    encoding: encoding,
  ).sendStreamed(client);
}

/// Sends the GET request with the specified URI, headers, body,
/// and encoding. Transforms [ByteStream] to
/// [Map<String, dynamic>] for every event.
Future<Stream<Map<String, dynamic>>> sseRequestPostSendStreamed({
  required Uri uri,
  Client? client,
  Map<String, String>? headers,
  Map<String, dynamic>? body,
  Encoding? encoding,
}) {
  return SseRequest.post(
    uri: uri,
    headers: headers,
    body: body,
    encoding: encoding,
  ).sendStreamed(client);
}
