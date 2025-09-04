import 'dart:developer' as dev;

import '../stream_event_transformer/event_sink_transformer.dart';
import '../exceptions.dart';

/// SSE event byte stream splitter. Separates each event from multiple events.
///
/// For more information about the SSE protocol, refer to the documentation: https://html.spec.whatwg.org/multipage/server-sent-events.html
final class SseByteStreamSplitterSink
    extends EventSinkTransformer<List<int>, Iterable<int>> {
  const SseByteStreamSplitterSink(super.outputSink);

  /// Splits the input byte event into separate SSE events using the separator.
  Iterable<List<int>> filterBetweenSeparator(final List<int> event) sync* {
    int start = 0;

    for (int i = 0; i < event.length - 1; i++) {
      if (event[i] == 10 && event[i + 1] == 10) {
        yield event.sublist(start, i);
        start = i + 2;
      }
    }

    if (start < event.length - 1) {
      yield event.sublist(start, event.length - 1);
    }
  }

  /// Adds a splitted byte SSE event to the output sink.
  @override
  void add(List<int> event) {
    try {
      for (final splittedEvent in filterBetweenSeparator(event)) {
        addToSink(splittedEvent);
      }
    } catch (e) {
      final exeption = ByteStreamSplitException(
        message: "Failed to split SSE",
        source: event,
        originalExeption: e,
      );
      addError(exeption);
      dev.log(exeption.toString());
      dev.inspect(event);
    }
  }
}
