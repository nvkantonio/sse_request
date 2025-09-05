import 'dart:async';

import 'package:http/http.dart';
import 'package:meta/meta.dart';

import 'sse_source_controller_base.dart';

typedef EventErrorAction = FutureOr<void> Function(
  SseSourceController controller,
  Object error,
  StackTrace stackTrace,
);

/// Simple implementation of [SseSourceControllerBase] where the `onErrorEvent`
/// action can be specified in parameter, allowing the implementation of
/// reconnection logic.
final class SseSourceController extends SseSourceControllerBase {
  /// Creates an [SseSourceController] with the given parameters.
  ///
  /// Simple implementation of [SseSourceControllerBase] where the [actionOnErrorEvent] action can be specified, allowing the implementation
  /// of reconnection logic.
  ///
  /// {@macro sse_source_controller_base}
  ///
  /// - [doDisposeOnClientException] if `true`, disposes the controller when
  /// a ClientException is thrown, otherwise, calls `clear()`.
  /// Works only if the [actionOnErrorEvent] parameter is not specified.
  ///
  /// ---
  ///
  /// #### Example usage of [SseSourceController]:
  /// ```dart
  /// // Create an SSE GET request.
  /// final request = SseRequest.get(
  ///   uri: Uri.parse('your_api_uri'),
  /// );
  ///
  /// final controller = SseSourceController(
  ///   // The name used to distinguish connection events for multiple streams.
  ///   name: 'Name:1',
  ///   // Specify the builder function for obtaining the event stream.
  ///   sseStreamBuilder: request.sendStreamed,
  /// );
  ///
  /// // Establish an SSE connection.
  /// // Nothing is sent until this happens.
  /// final subscription = controller.stream.listen((event) {});
  ///
  /// // Demonstration delay.
  /// await Future.delayed(Duration(seconds: 10));
  ///
  /// /// Don't forget to close the StreamSubscription to avoid memory leaks.
  /// subscription.cancel();
  ///
  /// // `dispose()` or `clear()` methods can be used to force close connection
  /// // using controller, where `dispose()` ensures you cannot use
  /// // the controller again.
  /// controller.dispose();
  /// ```
  ///
  /// ---
  ///
  /// #### Example usage of [actionOnErrorEvent]:
  /// ```dart
  /// actionOnErrorEvent: (controller, error, st) async {
  ///   /// With the callback of `SseSourceController controller`, you can
  ///   /// handle how the controller reacts to certain errors.
  ///   try {
  ///     print(error.toString());
  ///
  ///     // Cancel current event listener and close http client
  ///     await controller.clear();
  ///
  ///     // Connect new event listener
  ///     await controller.connectEventListener(sseStreamBuilder);
  ///   } catch (e) {
  ///     // On unsuccessful connection retry, you can dispose the
  ///     // controller or retry again after a delay.
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
