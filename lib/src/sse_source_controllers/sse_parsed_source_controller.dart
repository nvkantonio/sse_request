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

final class SseParsedSourceController<T> extends SseSourceControllerBase<T> {
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
