import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

http.Response apiOk(dynamic data, {String message = 'ok'}) => http.Response(
      jsonEncode({'status': 'success', 'message': message, 'data': data}),
      200,
      headers: _jsonHeaders,
    );

http.Response apiError(String message, int status) => http.Response(
      jsonEncode({'status': 'error', 'message': message, 'data': null}),
      status,
      headers: _jsonHeaders,
    );

/// A MockClient standing in for the Khoga backend (our MSW equivalent).
/// `/profile` requires the Bearer token, so a passing login proves the token was
/// attached after authentication.
MockClient authBackend({
  Map<String, dynamic>? profile,
  bool mustChangePassword = false,
  bool loginFails = false,
}) {
  final p = profile ??
      <String, dynamic>{
        'id': 'u1',
        'username': 'cashier01',
        'fullName': 'Nguyễn Thu Ngân',
        'role': 'CASHIER',
        'email': null,
        'phone': null,
        'storeId': null,
      };
  return MockClient((req) async {
    final path = req.url.path;
    if (path.endsWith('/auth/login')) {
      if (loginFails) return apiError('Sai tài khoản hoặc mật khẩu', 401);
      return apiOk({'token': 'jwt-1', 'role': p['role'], 'mustChangePassword': mustChangePassword});
    }
    if (path.endsWith('/profile')) {
      if (req.headers['Authorization'] != 'Bearer jwt-1') return apiError('Yêu cầu xác thực', 401);
      return apiOk(p);
    }
    return apiError('Not mocked: $path', 404);
  });
}
