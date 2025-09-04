import 'dart:async';
import 'package:meta/meta.dart';

/// Isolation wrapper for StreamController with dispose
abstract class StreamSourceController<T> {
  const StreamSourceController(this.eventStreamController);

  Stream<T> get stream => eventStreamController.stream;

  Future<dynamic> get done => eventStreamController.done;

  bool get hasListener => eventStreamController.hasListener;

  StreamSink<T> get sink => eventStreamController.sink;

  bool get isClosed => eventStreamController.isClosed;

  /// Internal event stream controller
  @protected
  final StreamController<T> eventStreamController;

  /// Dispose controller.
  @mustCallSuper
  Future<void> dispose() async {
    if (!isClosed) {
      await eventStreamController.close();
    }
  }
}
