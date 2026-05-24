import 'dart:async';
import 'package:meta/meta.dart';

/// Isolation wrapper for StreamController with dispose
class StreamSourceController<T> implements StreamController<T> {
  const StreamSourceController(this.eventStreamController);

  /// Internal event stream controller
  @protected
  final StreamController<T> eventStreamController;

  @override
  Stream<T> get stream => eventStreamController.stream;

  @override
  Future<dynamic> get done => eventStreamController.done;

  @override
  bool get hasListener => eventStreamController.hasListener;

  @override
  StreamSink<T> get sink => eventStreamController.sink;

  @override
  bool get isClosed => eventStreamController.isClosed;

  @override
  bool get isPaused => eventStreamController.isPaused;

  @override
  FutureOr<dynamic> Function()? get onCancel => eventStreamController.onCancel;

  @override
  void Function()? get onListen => eventStreamController.onListen;

  @override
  void Function()? get onPause => eventStreamController.onPause;

  @override
  void Function()? get onResume => eventStreamController.onResume;

  @override
  int get hashCode => sink.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreamSourceController && sink == other.sink;

  @override
  set onCancel(FutureOr<dynamic> Function()? value) =>
      eventStreamController.onCancel = value;

  @override
  set onListen(void Function()? value) =>
      eventStreamController.onListen = value;

  @override
  set onPause(void Function()? value) => eventStreamController.onPause = value;

  @override
  set onResume(void Function()? value) =>
      eventStreamController.onResume = value;

  /// Dispose controller.
  @mustCallSuper
  Future<void> dispose() async {
    if (!isClosed) {
      await eventStreamController.close();
    }
  }

  @override
  void add(T event) => eventStreamController.add(event);

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      eventStreamController.addError(error, stackTrace);

  @override
  Future<dynamic> addStream(Stream<T> source, {bool? cancelOnError}) =>
      eventStreamController.addStream(source, cancelOnError: cancelOnError);

  @override
  Future<dynamic> close() => eventStreamController.close();
}
