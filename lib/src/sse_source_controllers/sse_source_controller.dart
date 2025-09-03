import 'dart:async';

import 'package:http/http.dart';
import 'package:meta/meta.dart';

import 'sse_source_controller_base.dart';

typedef EventErrorAction = FutureOr<void> Function(
  Object error,
  SseSourceController controller,
  Object error,
  StackTrace stackTrace,
);

final class SseSourceController extends SseSourceControllerBase {
  SseSourceController({
    required super.name,
    required super.sseStreamBuilder,
    super.isBroadCast,
    super.doDisposeOnCancel,
    bool doDisposeOnClientExeption = false,
    super.onNewConnection,
    super.onConnected,
    super.onCloseConnection,
    super.onCancel,
    EventErrorAction? actionOnErrorEvent,
  }) {
    if (actionOnErrorEvent != null) {
      _actionOnErrorEvent = actionOnErrorEvent;
    } else {
      // Default behavior on error event
      _actionOnErrorEvent = (
        SseSourceController controller,
        Object error,
        StackTrace stackTrace,
      ) async {
        if (error is ClientException) {
          doDisposeOnClientExeption
              ? await controller.dispose()
              : await controller.clear();
        }
      };
    }
  }

  /// Action to perform when an error event occurs.
  late final EventErrorAction _actionOnErrorEvent;

  @override
  @protected
  void onDataEvent(Map<String, dynamic> event) =>
      eventStreamController.add(event);

  @override
  @protected
  void onErrorEvent(Object error, StackTrace st) {
    eventStreamController.addError(error, st);
    _actionOnErrorEvent(this, error, st);
  }

  @override
  @protected
  void onDoneEvent() {}
}
