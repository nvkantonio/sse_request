import 'dart:async';

/// [EventSink] simple implementation
abstract class EventSinkTransformer<T, S> implements EventSink<T> {
  const EventSinkTransformer(this.outputSink);

  final EventSink<S> outputSink;

  void addToSink(S event) => outputSink.add(event);

  @override
  void add(T event);

  @override
  void addError(e, [st]) => outputSink.addError(e, st);

  @override
  void close() => outputSink.close();
}
