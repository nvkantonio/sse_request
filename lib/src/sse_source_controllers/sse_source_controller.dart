import 'dart:async';

import 'package:http/http.dart';
import 'package:meta/meta.dart';

import 'sse_source_controller_base.dart';

typedef EventErrorAction = FutureOr<void> Function(
  SseSourceController controller,
  Object error,
  StackTrace stackTrace,
);

/// Implementation of [SseSourceControllerBase] where the `onErrorEvent`
/// action can be specified in parameter, allowing configuration of
/// reconnection logic.
///
/// If you need to specify a custom object for the stream, use
/// [SseParsedSourceController] instead.
///
/// If you need more precise control prefer implementing
/// [SseSourceControllerBase]
///
final class SseSourceController
    extends SseSourceControllerBase<Map<String, dynamic>> {
  ///
  /// Creates an [SseSourceController] with the given parameters.
  ///
  /// Implementation of [SseSourceControllerBase] where the [actionOnErrorEvent] action can be specified, allowing the implementation
  /// of reconnection logic.
  ///
  /// If you need to specify a custom object for the stream, use
  /// [SseParsedSourceController] instead.
  ///
  /// If you need more precise control prefer implementing
  /// [SseSourceControllerBase]
  ///
  /// {@macro sse_source_controller_base}
  ///
  /// {@template do_dispose_on_client_exeption}
  /// - [doDisposeOnClientException] if `true`, disposes the controller when
  /// a ClientException is thrown, otherwise, calls `clear()`.
  /// Works only if the [actionOnErrorEvent] parameter is not specified.
  ///
  /// {@endtemplate}
  ///
  /// ---
  ///
  /// #### Example usage of [SseSourceController]:
  /// ```dart
  /// final controller = SseSourceController(
  ///   // This name used to distinguish connection events for multiple streams.
  ///   name: 'Name:1',
  ///   // Specify the builder function for obtaining the event stream.
  ///   sseStreamBuilder: (client) => sseRequestGetSendStreamed(
  ///     uri: Uri.parse('your_api_uri'),
  ///     client: client,
  ///   ),
  /// );
  ///
  /// // Establish an SSE connection.
  /// //
  /// // Nothing is sent until the first listener is attached.
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
  ///
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
  Future<void> onErrorEvent(Object error, StackTrace st) async {
    eventStreamController.addError(error, st);
    await _actionOnErrorEvent(this, error, st);
  }

  @override
  @protected
  void onDoneEvent() {}
}
