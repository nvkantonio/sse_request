import 'stream_event_transformer/stream_event_transformer.dart';
import '../sse_transformers.dart';

typedef SseStreamSplitter =
    SimpleStreamEventSinkTransformer<List<int>, List<int>>;

typedef SseStreamParser =
    SimpleStreamEventSinkTransformer<String, Map<String, dynamic>>;

/// SseStreamSplitterSink splitter creating shorthand
SseStreamSplitter get sseStreamSplitter =>
    SseStreamSplitter.fromSink(SseByteStreamSplitterSink.new);

/// SseStreamParseSink splitter creating shorthand
SseStreamParser get sseStreamParser =>
    SseStreamParser.fromSink(SseStreamParserSink.new);
