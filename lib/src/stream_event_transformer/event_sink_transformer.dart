import 'dart:async';

/// Simple implementation of [EventSink] for transforming events.
abstract class EventSinkTransformer<T, S> implements EventSink<T> {
  /// Creates an [EventSinkTransformer] with the given output sink.
  const EventSinkTransformer(this.outputSink);

  /// The output sink to which transformed events are added.
  final EventSink<S> outputSink;

  /// Adds a transformed event to the output sink.
  void addToSink(S event) => outputSink.add(event);

  @override
  void add(T event);

  @override
  void addError(Object e, [StackTrace? st]) => outputSink.addError(e, st);

  @override
  void close() => outputSink.close();
}
