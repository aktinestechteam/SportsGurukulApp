class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    this.message = 'Something went wrong.',
    this.errors = const {},
    this.isNetworkError = false,
  });

  factory ApiException.network() => const ApiException(
    statusCode: 0,
    message: 'Network error. Check your connection.',
    isNetworkError: true,
  );

  factory ApiException.timeout() => const ApiException(
    statusCode: 0,
    message: 'The request timed out. Please try again.',
  );

  final int statusCode;
  final String message;
  final Map<String, List<String>> errors;
  final bool isNetworkError;

  String get friendlyMessage {
    if (errors.isNotEmpty) {
      final firstError = errors.entries.first.value.firstOrNull;
      if (firstError != null && firstError.isNotEmpty) {
        return firstError;
      }
    }
    return message;
  }

  bool get isUnauthorized => statusCode == 401;
  bool get isConflict => statusCode == 409;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
