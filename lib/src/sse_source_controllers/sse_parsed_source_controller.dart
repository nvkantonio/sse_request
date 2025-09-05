import 'dart:async';

import 'package:http/http.dart';
import 'package:meta/meta.dart';

import 'sse_source_controller_base.dart';

typedef ParsedEventErrorAction = FutureOr<void> Function(
  SseParsedSourceController controller,
  Object error,
  StackTrace stackTrace, [
  Map<String, dynamic>? sourceEvent,
]);

/// Implementation of [SseSourceControllerBase] where the `onErrorEvent`
/// and `eventParser` action can be specified in parameter,
/// allowing configuration of reconnection logic and parsing of
/// each event into a specified object type.
///
/// If you don't need to specify a custom object for the stream, use
/// [SseSourceController].
///
/// If you need more precise control prefer implementing
/// [SseSourceControllerBase]
///
final class SseParsedSourceController<T> extends SseSourceControllerBase<T> {
  ///
  /// Implementation of [SseSourceControllerBase] where the `onErrorEvent`
  /// and `eventParser` action can be specified in parameter,
  /// allowing configuration of reconnection logic and parsing each event to
  /// specified object type.
  ///
  /// If you don't need to specify a custom object for the stream, use
  /// [SseSourceController].
  ///
  /// If you need more precise control prefer implementing
  /// [SseSourceControllerBase]
  ///
  ///
  /// {@macro sse_source_controller_base}
  ///
  /// {@macro do_dispose_on_client_exeption}
  ///
  /// ---
  ///
  /// Example usage of [SseParsedSourceController]
  ///
  /// ```dart
  ///  // Create an SSE GET request
  /// final request = SseRequest.get(
  ///   uri: Uri.parse('your_api_uri'),
  /// );
  ///
  /// /// Use [SseParsedSourceController<T>] instead of
  /// /// [SseSourceController] to set a custom type for the stream.
  /// final controller = SseParsedSourceController<String>(
  ///   // The name used to distinguish connection events for multiple streams.
  ///   name: 'Name:1',
  ///   // Specify the builder function for obtaining the event stream.
  ///   sseStreamBuilder: request.sendStreamed,
  ///   // Invoked on every new event.
  ///   // Expects to return a value of specified type
  ///   // or throw an error, which will call [onErrorEvent],
  ///   // so you don't need to duplicate error handling logic.
  ///   eventParser: (Map<String, dynamic> event) {
  ///     // Implement your parser here.
  ///     try {
  ///       return event.values.first;
  ///     } catch (e) {
  ///       // On unhandled exeption will call [onErrorEvent].
  ///       rethrow;
  ///     }
  ///   },
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
  SseParsedSourceController({
    required super.name,
    required super.sseStreamBuilder,
    required this.eventParser,
    super.isBroadCast,
    super.doDisposeOnCancel,
    bool doDisposeOnClientExeption = false,
    super.onNewConnection,
    super.onConnected,
    super.onCloseConnection,
    super.onCancel,
    ParsedEventErrorAction? actionOnErrorEvent,
  }) {
    if (actionOnErrorEvent != null) {
      _actionOnErrorEvent = actionOnErrorEvent;
    } else {
      // Default behavior on error event
      _actionOnErrorEvent = (
        SseParsedSourceController controller,
        Object error,
        StackTrace stackTrace, [
        Map<String, dynamic>? sourceEvent,
      ]) async {
        if (error is ClientException) {
          doDisposeOnClientExeption
              ? await controller.dispose()
              : await controller.clear();
        }
      };
    }
  }

  FutureOr<T> Function(Map<String, dynamic> event) eventParser;

  late final ParsedEventErrorAction _actionOnErrorEvent;

  @override
  @protected
  FutureOr<void> onDataEvent(Map<String, dynamic> event) async {
    try {
      eventStreamController.add(await eventParser(event));
    } catch (e, st) {
      onErrorEvent(e, st, event);
    }
  }

  @override
  @protected
  FutureOr<void> onErrorEvent(
    Object error,
    StackTrace st, [
    Map<String, dynamic>? sourceEvent,
  ]) async {
    eventStreamController.addError(error, st);
    await _actionOnErrorEvent(this, error, st, sourceEvent);
  }

  @override
  @protected
  void onDoneEvent() {}
}
