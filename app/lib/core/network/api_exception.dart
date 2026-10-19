class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.fieldErrors = const {},
  });
  final int statusCode;
  final String code;
  final String message;
  final Map<String, List<String>> fieldErrors;
  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
