import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart';
import 'package:sse_request/sse_request.dart';
import 'package:sse_request/sse_transformers.dart';

extension RequestHandlers on BaseRequest {
  /// Returns a stream of parsed SSE events.
  ///
  /// If you need precise control over the event stream, prefer using
  /// [SseSourceController] or implementing [SseSourceControllerBase].
  ///
  /// [subName] is the subscription name. This name is used to
  /// distinguish connection events for multiple streams.
  /// [useBroadCast] determines if the stream is broadcast.
  ///
  Stream<Map<String, dynamic>> getRequestStream({
    required String subName,
    bool useBroadCast = false,
  }) {
    final controller = SseSourceController(
      isBroadCast: useBroadCast,
      name: subName,
      sseStreamBuilder: (client) => sendStreamedRequest(client: client),
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

  /// Sends the request and transforms [ByteStream] to
  /// [Map<String, dynamic>] for every event.
  ///
  /// To connect to a data stream, package use `BaseRequest`'s `send()`,
  /// which returns a `StreamedResponse`.
  /// Instead of waiting for the entire response, you can access
  /// `streamedResponse.stream` to receive data as it arrives.
  /// This stream provides raw bytes (`ByteData`), which should be decoded
  /// and parsed into usable events.
  Future<Stream<Map<String, dynamic>>> sendStreamedRequest({
    Client? client,
    Encoding? encoding,
  }) async {
    Encoding getEncoding() {
      if (encoding != null) return encoding;
      if (this case Request request) {
        return request.encoding;
      }
      return utf8;
    }

    try {
      final streamedResponse =
          await (client != null ? client.send(this) : send());

      final transformedResponseStream = streamedResponse.stream
          .transform(getEncoding().decoder)
          .transform(sseStreamSplitter)
          .transform(sseStreamParser);

      return transformedResponseStream;
    } catch (e) {
      rethrow;
    }
  }
}
