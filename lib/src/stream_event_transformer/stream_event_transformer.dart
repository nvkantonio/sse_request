import 'dart:async';

import 'package:meta/meta.dart';

import 'event_sink_transformer.dart';

typedef EventSinkConstructor<S> = EventSinkTransformer Function(EventSink<S>);

/// A simple implementation of [StreamTransformerBase] for event sinks.
class SimpleStreamEventSinkTransformer<T, S>
    extends StreamTransformerBase<T, S> {
  /// Creates a [SimpleStreamEventSinkTransformer] with the given
  /// event sink constructor.
  const SimpleStreamEventSinkTransformer(this.eventSink);

  /// Factory constructor to create a transformer from a sink constructor.
  factory SimpleStreamEventSinkTransformer.fromSink(
    final EventSinkConstructor<S> mapSink,
  ) =>
      SimpleStreamEventSinkTransformer(mapSink);

  /// The event sink constructor used for transformation.
  final EventSinkConstructor<S> eventSink;

  /// Maps the provided sink using the event sink constructor.
  @protected
  EventSink mapSink(sink) => eventSink(sink);

  /// Binds the transformer to the provided stream.
  @override
  Stream<S> bind(final Stream<T> stream) =>
      Stream<S>.eventTransformed(stream, mapSink);
}
