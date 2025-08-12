import 'dart:async';

import 'package:meta/meta.dart';

import 'event_sink_transformer.dart';

typedef EventSinkConstructor<S> = EventSinkTransformer Function(EventSink<S>);

/// [StreamTransformerBase] simple implementation
abstract class StreamEventSinkTransformerBase<T, S>
    extends StreamTransformerBase<T, S> {
  const StreamEventSinkTransformerBase();

  @protected
  EventSink mapSink(EventSink<S> sink);

  @override
  Stream<S> bind(final Stream<T> stream) =>
      Stream<S>.eventTransformed(stream, mapSink);
}

/// [StreamEventSinkTransformerBase] simple implementation
class SimpleStreamEventSinkTransformer<T, S>
    extends StreamEventSinkTransformerBase<T, S> {
  const SimpleStreamEventSinkTransformer(this.eventSink);

  factory SimpleStreamEventSinkTransformer.fromSink(
    final EventSinkConstructor<S> mapSink,
  ) => SimpleStreamEventSinkTransformer(mapSink);

  final EventSinkConstructor<S> eventSink;

  @override
  EventSink mapSink(sink) => eventSink(sink);
}
