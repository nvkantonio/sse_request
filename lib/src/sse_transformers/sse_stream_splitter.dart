import 'dart:developer' as dev;

import '../stream_event_transformer/event_sink_transformer.dart';
import '../exceptions.dart';

///  SSE event stream splitter. Separates each event from multiple events
///
/// For more info about SSE protocol refer to documentation https://html.spec.whatwg.org/multipage/server-sent-events.html
final class SseStreamSplitterSink extends EventSinkTransformer<String, String> {
  const SseStreamSplitterSink(super.outputSink);

  Iterable<String> filterBetweenSeparator(final String event) sync* {
    int start = 0;

    for (int i = 0; i < event.length - 1; i++) {
      if (event[i] == '\n' && event[i + 1] == '\n') {
        yield event.substring(start, i);
        start = i + 2;
      }
    }

    if (start < event.length - 1) {
      yield event.substring(start, event.length - 1);
    }
  }

  @override
  void add(String event) {
    try {
      for (final splittedEvent in filterBetweenSeparator(event)) {
        addToSink(splittedEvent);
      }
    } catch (e) {
      final exeption = ByteStreamSplitException(
        message: "Failed to split sse",
        source: (event),
        originalExeption: e,
      );
      addError(exeption);
      dev.log(exeption.toString());
    }
  }
}
