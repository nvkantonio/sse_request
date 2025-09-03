abstract class CustomFormatException extends FormatException {
  const CustomFormatException({
    String message = '',
    dynamic source,
    int? offset,
    this.originalExeption,
  }) : super(message, source, offset);

  final dynamic originalExeption;
}

abstract class CustomException implements Exception {
  const CustomException({
    this.message = '',
    this.source,
    this.originalExeption,
  });

  final String message;
  final dynamic source;
  final dynamic originalExeption;

  @override
  String toString() => message;
}

class ByteStreamSplitException extends CustomFormatException {
  const ByteStreamSplitException({
    super.message,
    super.source,
    super.offset,
    super.originalExeption,
  });
}

class SseParseException extends CustomFormatException {
  const SseParseException({
    super.message,
    super.source,
    super.offset,
    super.originalExeption,
  });
}

class SseConnectionExeption extends CustomException {
  const SseConnectionExeption({
    super.message,
    super.source,
    super.originalExeption,
  });
}
