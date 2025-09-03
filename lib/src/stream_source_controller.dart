import 'dart:async';
import 'package:meta/meta.dart';

abstract class StreamSourceController<T> {
  const StreamSourceController(this.eventStreamController);

  Stream<T> get stream => eventStreamController.stream;

  Future<dynamic> get done => eventStreamController.done;

  bool get hasListener => eventStreamController.hasListener;

  StreamSink<T> get sink => eventStreamController.sink;

  bool get isClosed => eventStreamController.isClosed;

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
