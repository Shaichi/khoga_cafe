import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

http.Response apiOk(dynamic data, {String message = 'ok', int status = 200}) => http.Response(
      jsonEncode({'status': 'success', 'message': message, 'data': data}),
      status,
      headers: _jsonHeaders,
    );

http.Response apiError(String message, int status) => http.Response(
      jsonEncode({'status': 'error', 'message': message, 'data': null}),
      status,
      headers: _jsonHeaders,
    );

Map<String, dynamic> _shift({String? register, dynamic startingCash}) => {
      'id': 'shift-1',
      'storeId': 's1',
      'cashierId': 'u1',
      'posRegisterId': register ?? 'POS-01',
      'startingCash': startingCash ?? 1000000,
      'status': 'OPEN',
      'startTime': '2026-06-28T08:00:00',
    };

/// A MockClient standing in for the Khoga backend (our MSW equivalent). Every
/// endpoint except /auth/login requires the Bearer token, so a passing flow
/// proves the token was attached after authentication.
MockClient authBackend({
  Map<String, dynamic>? profile,
  bool mustChangePassword = false,
  bool loginFails = false,
  bool hasOpenShift = false,
}) {
  final p = profile ??
      <String, dynamic>{
        'id': 'u1',
        'username': 'cashier01',
        'fullName': 'Nguyễn Thu Ngân',
        'role': 'CASHIER',
        'email': null,
        'phone': null,
        'storeId': 's1',
      };
  return MockClient((req) async {
    final path = req.url.path;
    if (path.endsWith('/auth/login')) {
      if (loginFails) return apiError('Sai tài khoản hoặc mật khẩu', 401);
      return apiOk({'token': 'jwt-1', 'role': p['role'], 'mustChangePassword': mustChangePassword});
    }
    if (req.headers['Authorization'] != 'Bearer jwt-1') return apiError('Yêu cầu xác thực', 401);

    if (path.endsWith('/profile')) return apiOk(p);
    if (path.endsWith('/shifts/active')) {
      if (!hasOpenShift) return apiError('Không có ca đang mở', 404);
      return apiOk(_shift());
    }
    if (path.endsWith('/shifts/open')) {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      return apiOk(
        _shift(register: body['posRegisterId'] as String?, startingCash: body['startingCash']),
        message: 'Đã mở ca',
        status: 201,
      );
    }
    return apiError('Not mocked: $path', 404);
  });
}
