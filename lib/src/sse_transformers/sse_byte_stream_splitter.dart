import '../stream_event_transformer/byte_stream_splitter_sink.dart';

/// Byte stream splitter for separating multiple SSE events in one steam event to multiple steam events each containing sigle SSE event
///
/// For more info about SSE protocol refer to documentation https://html.spec.whatwg.org/multipage/server-sent-events.html
final class SseByteStreamSplitterSink extends ByteStreamSplitterSink {
  const SseByteStreamSplitterSink(super.outputSink);

  @override
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
}
