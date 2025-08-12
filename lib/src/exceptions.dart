abstract class CustomFormatException extends FormatException {
  const CustomFormatException({
    String message = '',
    dynamic source,
    int? offset,
    this.originalExeption,
  }) : super(message, source, offset);

  final Object? originalExeption;
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
