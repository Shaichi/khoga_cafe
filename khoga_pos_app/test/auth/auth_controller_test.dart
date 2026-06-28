import 'package:flutter_test/flutter_test.dart';
import 'package:khoga_pos_app/api/api_client.dart';
import 'package:khoga_pos_app/api/auth_api.dart';
import 'package:khoga_pos_app/auth/auth_controller.dart';

import '../support/fake_backend.dart';

void main() {
  AuthController build() {
    final client = ApiClient(client: authBackend(), baseUrl: 'http://test/api/v1');
    return AuthController(client, AuthApi(client));
  }

  test('login attaches the bearer token (profile load proves it) and exposes the user', () async {
    final ctrl = build();
    expect(ctrl.isAuthenticated, isFalse);

    await ctrl.login('cashier01', 'Secret@123');

    expect(ctrl.isAuthenticated, isTrue);
    expect(ctrl.profile!.fullName, 'Nguyễn Thu Ngân');
    expect(ctrl.profile!.role, 'CASHIER');
  });

  test('logout clears the session', () async {
    final ctrl = build();
    await ctrl.login('cashier01', 'Secret@123');

    ctrl.logout();

    expect(ctrl.isAuthenticated, isFalse);
    expect(ctrl.profile, isNull);
  });
}
