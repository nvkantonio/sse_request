import 'dart:async';

import 'package:http/http.dart';
import 'package:meta/meta.dart';

import 'sse_source_controller_base.dart';

typedef EventErrorAction = FutureOr<void> Function(
  SseSourceController controller,
  Object error,
  StackTrace stackTrace,
);

/// Simple implementation of [SseSourceControllerBase] where the `onErrorEvent` action can be specified in parameter, allowing the implementation of reconnection logic.
final class SseSourceController extends SseSourceControllerBase {
  /// Creates an [SseSourceController] with the given parameters.
  ///
  /// Simple implementation of [SseSourceControllerBase] where the [actionOnErrorEvent] action can be specified, allowing the implementation of reconnection logic.
  ///
  /// [actionOnErrorEvent] takes `Function(SseSourceController controller, Object error, StackTrace stackTrace)`.
  ///
  /// {@macro sse_source_controller_base}
  ///
  /// [doDisposeOnClientException] if `true`, disposes the controller when a ClientException is thrown, otherwise, calls `clear()`. Works only if the [actionOnErrorEvent] parameter is not specified.
  ///
  /// Example usage of [actionOnErrorEvent]:
  /// ```dart
  /// actionOnErrorEvent: (controller, error, st) async {
  ///   /// With the callback of `SseSourceController controller`, you can handle how the controller reacts to certain errors.
  ///   try {
  ///     print(error.toString());
  ///
  ///     // Cancel current event listener and close http client
  ///     await controller.clear();
  ///
  ///     // Connect new event listener
  ///     await controller.connectEventListener(sseStreamBuilder);
  ///   } catch (e) {
  ///     // On unsuccessful connection retry, you can dispose the controller or retry again after a delay.
  ///     await controller.dispose();
  ///     rethrow;
  ///   }
  /// },
  /// ```

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
