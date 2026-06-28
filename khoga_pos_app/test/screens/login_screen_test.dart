import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:khoga_pos_app/api/api_client.dart';
import 'package:khoga_pos_app/api/auth_api.dart';
import 'package:khoga_pos_app/app.dart';
import 'package:khoga_pos_app/auth/auth_controller.dart';

import '../support/fake_backend.dart';

Widget _app(AuthController ctrl) =>
    ChangeNotifierProvider<AuthController>.value(value: ctrl, child: const KhogaPosApp());

void main() {
  testWidgets('logs in and shows the home screen on success (screen 01)', (tester) async {
    final client = ApiClient(client: authBackend(), baseUrl: 'http://test/api/v1');
    final ctrl = AuthController(client, AuthApi(client));
    await tester.pumpWidget(_app(ctrl));

    expect(find.text('Khoga Café'), findsOneWidget); // login shown
    await tester.enterText(find.byKey(const Key('username')), 'cashier01');
    await tester.enterText(find.byKey(const Key('password')), 'Secret@123');
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pumpAndSettle();

    expect(find.text('Nguyễn Thu Ngân'), findsOneWidget); // home greets the user
    expect(find.text('Khoga Café'), findsNothing);
  });

  testWidgets('shows the backend error and stays on login for bad credentials', (tester) async {
    final client = ApiClient(client: authBackend(loginFails: true), baseUrl: 'http://test/api/v1');
    final ctrl = AuthController(client, AuthApi(client));
    await tester.pumpWidget(_app(ctrl));

    await tester.enterText(find.byKey(const Key('username')), 'cashier01');
    await tester.enterText(find.byKey(const Key('password')), 'wrong');
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sai tài khoản'), findsOneWidget);
    expect(find.text('Khoga Café'), findsOneWidget); // still on login
  });
}
