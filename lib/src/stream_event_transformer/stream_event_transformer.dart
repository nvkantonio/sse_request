import 'dart:async';

import 'package:meta/meta.dart';

import 'event_sink_transformer.dart';

typedef EventSinkConstructor<S> = EventSinkTransformer Function(EventSink<S>);

/// [StreamTransformerBase] simple implementation
class SimpleStreamEventSinkTransformer<T, S>
    extends StreamTransformerBase<T, S> {
  const SimpleStreamEventSinkTransformer(this.eventSink);

  factory SimpleStreamEventSinkTransformer.fromSink(
    final EventSinkConstructor<S> mapSink,
  ) =>
      SimpleStreamEventSinkTransformer(mapSink);

  final EventSinkConstructor<S> eventSink;

  @protected
  EventSink mapSink(sink) => eventSink(sink);

  @override
  Stream<S> bind(final Stream<T> stream) =>
      Stream<S>.eventTransformed(stream, mapSink);
}
