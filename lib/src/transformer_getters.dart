import 'sse_transformers/sse_stream_splitter.dart';
import 'stream_event_transformer/stream_event_transformer.dart';
import '../sse_transformers.dart';

typedef SseByteStreamSplitter
    = SimpleStreamEventSinkTransformer<List<int>, List<int>>;

typedef SseStreamSplitter = SimpleStreamEventSinkTransformer<String, String>;

typedef SseStreamParser
    = SimpleStreamEventSinkTransformer<String, Map<String, dynamic>>;

/// SseByteStreamSplitterSink splitter creating shorthand
SseByteStreamSplitter get sseByteStreamSplitter =>
    SseByteStreamSplitter.fromSink(SseByteStreamSplitterSink.new);

/// SseStreamParseSink splitter creating shorthand
SseStreamSplitter get sseStreamSplitter =>
    SseStreamSplitter.fromSink(SseStreamSplitterSink.new);

/// SseStreamParseSink splitter creating shorthand
SseStreamParser get sseStreamParser =>
    SseStreamParser.fromSink(SseStreamParserSink.new);
