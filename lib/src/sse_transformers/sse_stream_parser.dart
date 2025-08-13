import 'dart:convert';

import '../stream_event_transformer/event_sink_transformer.dart';
import '../exceptions.dart';

/// SSE reponse event lines stream parser to [Map<String, *json* dynamic>] object
///
/// For more info about SSE protocol refer to documentation https://html.spec.whatwg.org/multipage/server-sent-events.html
final class SseStreamParserSink
    extends EventSinkTransformer<String, Map<String, dynamic>> {
  const SseStreamParserSink(super.outputSink);

  @override
  void add(String event) {
    try {
      addToSink(parseSse(event));
    } catch (e) {
      addError(e);
      rethrow;
    }
  }

  Map<String, dynamic> parseSse(String event) {
    final List<String> splittedEvent;

    try {
      // Split SSE event lines
      splittedEvent = event.split('\n');
    } catch (e) {
      throw SseParseException(
        message: 'Failed to split sse in lines',
        source: event,
        originalExeption: e,
      );
    }

    try {
      /// Parse each SEE line and combine to single [Map]
      return Map.fromEntries(splittedEvent.map(parseLine));
    } on SseParseException catch (e) {
      throw SseParseException(
        message: e.message,
        originalExeption: e.originalExeption,
        source: splittedEvent,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Parser for each separated line of SSE event
  // TODO(nvkantonio): rework this to properly utilize SSE documentation practicies
  static MapEntry<String, dynamic> parseLine(String line) {
    try {
      final separatorIndex = line.indexOf(': ');
      if (separatorIndex < 2) {
        throw SseParseException(message: 'Invalid line: $line');
      }

      final key = line.substring(0, separatorIndex);
      final value = line.substring(separatorIndex + 2, line.length);

      if (key.isEmpty || value.isEmpty) {
        throw SseParseException(message: 'Invalid line: $line');
      }

      dynamic decodedValue;
      if (value.startsWith('{') && value.endsWith('}')) {
        decodedValue = jsonDecode(value);
      }

      return MapEntry<String, dynamic>(key, decodedValue ?? value);
    } on SseParseException {
      rethrow;
    } catch (e) {
      throw SseParseException(
        message: 'Failed to parse sse line: $line',
        originalExeption: e,
      );
    }
  }
}
