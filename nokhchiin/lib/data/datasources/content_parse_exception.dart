class ContentParseException implements Exception {
  const ContentParseException({
    required this.file,
    required this.key,
    required this.message,
  });

  final String file;
  final String key;
  final String message;

  @override
  String toString() => 'ContentParseException($file[$key]): $message';
}
