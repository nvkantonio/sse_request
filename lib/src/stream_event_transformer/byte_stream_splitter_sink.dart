import '../exceptions.dart';
import 'event_sink_transformer.dart';

/// Byte stream splitter for separating response byte data depending on filter overrides
abstract class ByteStreamSplitterSink
    extends EventSinkTransformer<List<int>, Iterable<int>> {
  const ByteStreamSplitterSink(super.outputSink);

  Iterable<List<int>> filterBetweenSeparator(List<int> event);

  @override
  void add(List<int> event) {
    try {
      for (final splittedEvent in filterBetweenSeparator(event)) {
        addToSink(splittedEvent);
      }
    } catch (e) {
      final exeption = ByteStreamSplitException(
        message: "Failed to split sse",
        source: event,
        originalExeption: e,
      );
      addError(exeption);
      throw exeption;
    }
  }
}
