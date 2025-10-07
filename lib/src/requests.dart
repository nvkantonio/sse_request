import 'dart:convert';
import 'package:sse_request/sse_request.dart';

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
