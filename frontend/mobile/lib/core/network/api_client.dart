import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../errors/api_exception.dart';
import '../storage/token_storage.dart';

class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    http.Client? httpClient,
    String? baseUrl,
    this.onAuthExpired,
  }) : _tokenStorage = tokenStorage,
       _http = httpClient ?? http.Client(),
       _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final TokenStorage _tokenStorage;
  final http.Client _http;
  final String _baseUrl;

  void Function()? onAuthExpired;

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    final accessToken = await _tokenStorage.readAccessToken();

    var response = await _execute(
      () => _dispatch(method, uri, body: body, accessToken: accessToken),
    );

    if (response.statusCode == 401 && !_isAuthEndpoint(path)) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        final newToken = await _tokenStorage.readAccessToken();
        response = await _execute(
          () => _dispatch(method, uri, body: body, accessToken: newToken),
        );
      }
    }

    return _handleResponse(response, path);
  }

  Future<http.Response> _dispatch(
    String method,
    Uri uri, {
    Object? body,
    String? accessToken,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };

    final encodedBody = body == null ? null : jsonEncode(body);

    return switch (method) {
      'GET' =>
        await _http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: AppConfig.receiveTimeoutSeconds)),
      'POST' =>
        await _http
            .post(uri, headers: headers, body: encodedBody)
            .timeout(const Duration(seconds: AppConfig.receiveTimeoutSeconds)),
      'PUT' =>
        await _http
            .put(uri, headers: headers, body: encodedBody)
            .timeout(const Duration(seconds: AppConfig.receiveTimeoutSeconds)),
      'DELETE' =>
        await _http
            .delete(uri, headers: headers)
            .timeout(const Duration(seconds: AppConfig.receiveTimeoutSeconds)),
      _ => throw ApiException(
        statusCode: 0,
        message: 'Unsupported HTTP method: $method',
      ),
    };
  }

  Future<http.Response> _execute(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request();
    } on TimeoutException {
      throw ApiException.timeout();
    } on http.ClientException {
      throw ApiException.network();
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException.network();
    }
  }

  bool _isAuthEndpoint(String path) =>
      path.endsWith('/auth/login') ||
      path.endsWith('/auth/refresh') ||
      path.endsWith('/auth/logout') ||
      path.endsWith('/auth/forgot-password') ||
      path.endsWith('/auth/reset-password') ||
      path.endsWith('/auth/register');

  Future<bool> _tryRefresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final response = await _execute(
        () => _dispatch(
          'POST',
          Uri.parse('$_baseUrl/auth/refresh'),
          body: {'refreshToken': refreshToken},
        ),
      );

      if (response.statusCode != 200) {
        return false;
      }

      final envelope =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final data = envelope['data'] as Map<String, dynamic>?;
      if (data == null) {
        return false;
      }

      final newAccess = data['accessToken'] as String?;
      final newRefresh = data['refreshToken'] as String?;
      if (newAccess == null ||
          newAccess.isEmpty ||
          newRefresh == null ||
          newRefresh.isEmpty) {
        return false;
      }

      await _tokenStorage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  dynamic _handleResponse(http.Response response, String requestPath) {
    final body = utf8.decode(response.bodyBytes);
    dynamic payload;

    if (body.isNotEmpty) {
      try {
        payload = jsonDecode(body);
      } on FormatException {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Unexpected server response.',
        );
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (payload is Map<String, dynamic>) {
        return payload['data'];
      }
      return payload;
    }

    if (response.statusCode == 401 && !_isAuthEndpoint(requestPath)) {
      onAuthExpired?.call();
    }

    String message = 'Request failed with status ${response.statusCode}.';
    Map<String, List<String>> errors = const {};

    if (payload is Map<String, dynamic>) {
      final payloadMessage = payload['message'];
      if (payloadMessage is String && payloadMessage.isNotEmpty) {
        message = payloadMessage;
      }

      final payloadErrors = payload['errors'];
      if (payloadErrors is Map) {
        errors = payloadErrors.map(
          (key, value) => MapEntry(
            key.toString(),
            value is List
                ? value.map((e) => e.toString()).toList()
                : [value.toString()],
          ),
        );
      }
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: message,
      errors: errors,
    );
  }
}
