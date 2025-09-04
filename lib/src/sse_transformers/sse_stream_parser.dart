import 'dart:convert';
import 'dart:developer' as dev;

import '../stream_event_transformer/event_sink_transformer.dart';
import '../exceptions.dart';

/// Raw SSE response event parser to [Map<String, dynamic>].
///
/// For more information about the SSE protocol, refer to the documentation: https://html.spec.whatwg.org/multipage/server-sent-events.html
final class SseStreamParserSink
    extends EventSinkTransformer<String, Map<String, dynamic>> {
  const SseStreamParserSink(super.outputSink);

  /// Adds a parsed SSE event to the output sink as a map.
  @override
  void add(String event) {
    try {
      addToSink(parseSse(event));
    } on SseParseException catch (e) {
      addError(e);
      dev.log(e.toString());
    } catch (e) {
      addError(e);
      dev.log(e.toString());
      rethrow;
    }
  }

  /// Parses a raw SSE event string into a map.
  Map<String, dynamic> parseSse(String event) {
    final List<String> splittedEvent;

    try {
      // Split SSE event lines
      splittedEvent = event.split('\n');
    } catch (e) {
      throw SseParseException(
        message: 'Failed to split SSE into lines',
        source: event,
        originalExeption: e,
      );
    }

    try {
      /// Parse each SSE line and combine into a single [Map]
      return Map.fromEntries(splittedEvent.map(parseLine));
    } on SseParseException catch (e) {
      throw SseParseException(
        message: e.message,
        originalExeption: e.originalExeption,
        source: event,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Parses each separated line of an SSE event.
  // TODO(nvkantonio): Rework this to properly utilize SSE documentation practices
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
        message: 'Failed to parse SSE line: $line',
        originalExeption: e,
      );
    }
  }
}
