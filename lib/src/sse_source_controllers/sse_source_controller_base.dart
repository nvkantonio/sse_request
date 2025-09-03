import 'dart:async';

import 'package:http/http.dart';
import 'package:meta/meta.dart';

import '../stream_source_controller.dart';
import '../../sse_transformers.dart';

typedef ConnectionStreamBuilder = FutureOr<Stream<Map<String, dynamic>>>
    Function(Client client);

abstract class SseSourceControllerBase
    extends StreamSourceController<Map<String, dynamic>> {
  SseSourceControllerBase({
    required this.name,
    required ConnectionStreamBuilder sseStreamBuilder,
    bool isBroadCast = false,
    this.doDisposeOnCancel = true,
    this.onNewConnection,
    this.onConnected,
    this.onCloseConnection,
    this.onCancel,
  }) : super(isBroadCast ? StreamController.broadcast() : StreamController()) {
    eventStreamController
      ..onListen = () async {
        if (!isConnected) {
          await connectEventListener(sseStreamBuilder);
        }
      }
      ..onCancel = () async {
        if (!eventStreamController.hasListener) {
          if (doDisposeOnCancel) {
            await dispose();
          } else {
            await clear();
          }
          onCancel?.call(name, wasConnected);
        }
      };
  }

  final String name;

  bool doDisposeOnCancel;

  Function(String name)? onNewConnection;
  Function(String name)? onConnected;
  Function(String name, bool wasConnected)? onCloseConnection;
  Function(String name, bool wasConnected)? onCancel;

  Client? _client;

  StreamSubscription? _currentStreamSub;

  bool _wasConnected = false;

  bool get wasConnected => _wasConnected;

  bool get isConnected => _currentStreamSub != null;

  Future<void> connectEventListener(
      ConnectionStreamBuilder sseStreamBuilder) async {
    assert(!isClosed,
        'Cannot connect event listener when controller already disposed');

    onNewConnection?.call(name);

    try {
      if (isConnected) await closeCurrentEventStream();

      _client ??= Client();

      final eventStream = await sseStreamBuilder(_client!);

      _currentStreamSub = eventStream.listen(
        onDataEvent,
        onError: onErrorEvent,
        onDone: onDoneEvent,
        cancelOnError: false,
      );

      _wasConnected = true;

      onConnected?.call(name);
    } catch (e, st) {
      eventStreamController.addError(
        SseConnectionExeption(
          message: 'Could not connect to SSE: $e',
          originalExeption: e,
        ),
        st,
      );
      await clear();
      rethrow;
    }
  }

  Future<void> closeCurrentEventStream() async {
    await _currentStreamSub?.cancel();
    _currentStreamSub = null;
    onCloseConnection?.call(name, _wasConnected);
  }

  Future<void> clear() async {
    assert(!isClosed, 'Cannot clear controller when already disposed');

    await closeCurrentEventStream();
    closeClient();
  }

  @override
  Future<void> dispose() async {
    assert(!isClosed, 'Cannot dispose controller when already disposed');

    await clear();
    eventStreamController.onCancel = () {
      onCancel?.call(name, wasConnected);
    };
    await super.dispose();
  }

  @protected
  FutureOr<void> onDataEvent(Map<String, dynamic> event);

  @protected
  FutureOr<void> onErrorEvent(Object error, StackTrace st);

  @protected
  FutureOr<void> onDoneEvent();

  @protected
  void closeClient() {
    _client?.close();
    _client = null;
  }
}
