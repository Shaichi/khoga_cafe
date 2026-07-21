import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

String get kApiBaseUrl {
  if (kIsWeb) return 'http://localhost:8080/api/v1';
  // Use computer's local Wi-Fi IP for physical devices (and emulators bridged to LAN)
  if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
    return 'http://10.33.25.194:8080/api/v1';
  }
  return 'http://localhost:8080/api/v1';
}

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

  ApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl = baseUrl ?? kApiBaseUrl;

  /// Set (or clear, with null) the bearer token sent on subsequent requests.
  void setToken(String? token) => _token = token;

  String? get token => _token;

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

  Future<dynamic> delete(String path) async {
    return _unwrap(
      await _client.delete(Uri.parse('$baseUrl$path'), headers: _headers),
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
