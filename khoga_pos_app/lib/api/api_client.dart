import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

/// Default backend base URL. `10.0.2.2` is the Android emulator's alias for the
/// host machine's `localhost`; for Chrome/desktop dev override with `localhost`.
const String kApiBaseUrl = kIsWeb
    ? 'http://localhost:8080/api/v1'
    : 'http://10.0.2.2:8080/api/v1';

/// Thrown when the backend returns an error envelope or a non-2xx status. Carries
/// the human-readable message from `ApiResponse.message` when available.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thin HTTP wrapper over the Khoga backend. Attaches the JWT as a Bearer header
/// (the backend's filter accepts either Bearer or the cookie) and unwraps the
/// standard `ApiResponse<T>` envelope, returning `data` or throwing [ApiException].
class ApiClient {
  final http.Client _client;
  final String baseUrl;
  String? _token;

  ApiClient({http.Client? client, this.baseUrl = kApiBaseUrl})
    : _client = client ?? http.Client();

  /// Set (or clear, with null) the bearer token sent on subsequent requests.
  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<dynamic> get(String path) async {
    return _unwrap(
      await _client.get(Uri.parse('$baseUrl$path'), headers: _headers),
    );
  }

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    return _unwrap(
      await _client.post(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
        body: jsonEncode(body ?? {}),
      ),
    );
  }

  Future<dynamic> put(String path, [Map<String, dynamic>? body]) async {
    return _unwrap(
      await _client.put(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
        body: jsonEncode(body ?? {}),
      ),
    );
  }

  dynamic _unwrap(http.Response res) {
    dynamic decoded;
    try {
      decoded = res.bodyBytes.isEmpty
          ? null
          : jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      decoded = null;
    }
    final isEnvelope = decoded is Map<String, dynamic>;
    final status = isEnvelope ? decoded['status'] : null;
    final isOk =
        res.statusCode >= 200 && res.statusCode < 300 && status != 'error';
    if (isOk) {
      return isEnvelope ? decoded['data'] : decoded;
    }
    final message = (isEnvelope && decoded['message'] is String)
        ? decoded['message'] as String
        : 'Đã có lỗi xảy ra (${res.statusCode})';
    throw ApiException(message, statusCode: res.statusCode);
  }
}
