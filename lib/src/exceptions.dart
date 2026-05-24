abstract class CustomFormatException extends FormatException {
  const CustomFormatException({
    String message = '',
    dynamic source,
    int? offset,
    this.originalException,
  }) : super(message, source, offset);

  final dynamic originalException;
}

abstract class CustomException implements Exception {
  const CustomException({
    this.message = '',
    this.source,
    this.originalException,
  });

  final String message;
  final dynamic source;
  final dynamic originalException;

  @override
  String toString() => message;
}

class ByteStreamSplitException extends CustomFormatException {
  const ByteStreamSplitException({
    super.message,
    super.source,
    super.offset,
    super.originalException,
  });
}

class SseParseException extends CustomFormatException {
  const SseParseException({
    super.message,
    super.source,
    super.offset,
    super.originalException,
  });
}

class SseConnectionException extends CustomException {
  const SseConnectionException({
    super.message,
    super.source,
    super.originalException,
  });
}
