import 'dart:async';

import 'package:http/http.dart';
import 'package:meta/meta.dart';

import '../stream_source_controller.dart';
import '../../sse_transformers.dart';

typedef ConnectionStreamBuilder = FutureOr<Stream<Map<String, dynamic>>>
    Function(Client client);

/// Base class for SSE source controllers. Manages connection lifecycle
/// and event handling. Sets up the event stream controller with
/// custom `onListen` and `onCancel`.
///
abstract class SseSourceControllerBase<T> extends StreamSourceController<T> {
  ///
  /// Manages connection lifecycle and event handling. Sets up the event stream
  /// controller with custom `onListen` and `onCancel`.
  ///
  /// {@template sse_source_controller_base}
  /// Use `stream.listen()` to establish an SSE connection. This stream is
  /// separate from the SSE stream, which means if the connection to the server
  /// is lost, a new SSE stream can be attached with `connectEventListener()`
  /// after calling the `clear()` method.
  ///
  /// - [name] is the name of the SSE subscription.
  ///
  /// - [sseStreamBuilder] is builder responsible for creating the SSE
  /// connection stream.
  ///
  /// - [isBroadCast] - if `true`, uses a broadcast stream controller,
  /// otherwise, uses a single-subscription stream controller.
  /// Defaults to `false`.
  ///
  /// - [doDisposeOnCancel] - if `true`, disposes the controller when
  /// the stream is cancelled, otherwise clears the controller.
  /// Defaults to `true`.
  ///
  /// - [onNewConnection] is optional callback invoked when
  /// a new SSE connection is inbound.
  ///
  /// - [onConnected] is optional callback invoked when
  /// SSE connection is established.
  ///
  /// - [onCloseConnection] is optional callback invoked when
  /// SSE connection is closed.
  ///
  /// - [onCancel] is optional callback invoked when the stream is cancelled,
  /// providing the controller name and connection status.
  /// {@endtemplate}
  ///
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

  /// The name of the SSE subscription.
  final String name;

  /// Whether to dispose the controller when cancelled.
  bool doDisposeOnCancel;

  /// Callback for when a new connection is created.
  Function(String name)? onNewConnection;

  /// Callback for when a connection is established.
  Function(String name)? onConnected;

  /// Callback for when a connection is closed.
  Function(String name, bool wasConnected)? onCloseConnection;

  /// Callback for when the controller is cancelled.
  Function(String name, bool wasConnected)? onCancel;

  Client? _client;

  StreamSubscription? _currentStreamSub;

  bool _wasConnected = false;

  bool get wasConnected => _wasConnected;

  /// Returns true if the connection is currently listened to.
  bool get isConnected => _currentStreamSub != null;

  /// Connects the HTTP event listener using the provided stream builder.
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

  /// Cancel the current HTTP event stream subscription.
  Future<void> closeCurrentEventStream() async {
    await _currentStreamSub?.cancel();
    _currentStreamSub = null;
    onCloseConnection?.call(name, _wasConnected);
  }

  /// Cancel the current HTTP event stream subscription and close the client.
  Future<void> clear() async {
    assert(!isClosed, 'Cannot clear controller when already disposed');

    await closeCurrentEventStream();
    closeClient();
  }

  /// Dispose controller.
  /// Call `clear()` and close stream controller.
  /// Non of the actions can be done after disposing.
  @override
  Future<void> dispose() async {
    assert(!isClosed, 'Cannot dispose controller when already disposed');

    await clear();

    // Ensure onCancel wont rerun dispose or clear
    eventStreamController.onCancel = () {
      onCancel?.call(name, wasConnected);
    };

    await super.dispose();
  }

  /// Handles incoming data events.
  @protected
  FutureOr<void> onDataEvent(Map<String, dynamic> event);

  /// Handles incoming error events.
  @protected
  FutureOr<void> onErrorEvent(Object error, StackTrace st);

  /// Handles stream completion event.
  @protected
  FutureOr<void> onDoneEvent();

  /// Closes the HTTP client.
  @protected
  void closeClient() {
    _client?.close();
    _client = null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SseSourceControllerBase &&
          name == other.name &&
          _client == other._client &&
          sink == other.sink;

  @override
  int get hashCode => Object.hash(name, _client, sink);
}
