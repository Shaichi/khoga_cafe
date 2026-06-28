import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:khoga_pos_app/api/api_client.dart';
import 'package:khoga_pos_app/api/auth_api.dart';

import '../support/fake_backend.dart';

// Tracer: proves the HTTP + ApiResponse-envelope + auth path end-to-end against a
// mocked transport (MockClient is our MSW equivalent).
void main() {
  group('AuthApi.login', () {
    test('posts credentials and returns token/role from the ApiResponse envelope', () async {
      late http.Request captured;
      final mock = MockClient((req) async {
        captured = req;
        return http.Response(
          jsonEncode({
            'status': 'success',
            'message': 'Đăng nhập thành công',
            'data': {'token': 'jwt-123', 'role': 'CASHIER', 'mustChangePassword': false},
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final api = AuthApi(ApiClient(client: mock, baseUrl: 'http://test/api/v1'));

      final res = await api.login('cashier01', 'Secret@123');

      expect(res.token, 'jwt-123');
      expect(res.role, 'CASHIER');
      expect(res.mustChangePassword, isFalse);
      expect(captured.url.toString(), 'http://test/api/v1/auth/login');
      expect(jsonDecode(captured.body), {'username': 'cashier01', 'password': 'Secret@123'});
    });

    test('throws ApiException carrying the backend message on an error response', () async {
      final mock = MockClient((req) async => http.Response(
            jsonEncode({'status': 'error', 'message': 'Sai tài khoản hoặc mật khẩu', 'data': null}),
            401,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ));
      final api = AuthApi(ApiClient(client: mock, baseUrl: 'http://test/api/v1'));

      expect(
        () => api.login('x', 'y'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('Sai tài khoản'))),
      );
    });
  });

  group('AuthApi profile/password', () {
    ApiClient client() => ApiClient(client: authBackend(), baseUrl: 'http://test/api/v1')..setToken('jwt-1');

    test('updateProfile sends contact fields and returns the merged profile', () async {
      final p = await AuthApi(client()).updateProfile(email: 'a@b.com', phone: '0900000000');
      expect(p.email, 'a@b.com');
      expect(p.phone, '0900000000');
    });

    test('changePassword succeeds for the right current password', () async {
      await AuthApi(client()).changePassword('Admin@123', 'NewPass@123');
    });

    test('changePassword throws on a wrong current password', () async {
      expect(
        () => AuthApi(client()).changePassword('wrong', 'NewPass@123'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
