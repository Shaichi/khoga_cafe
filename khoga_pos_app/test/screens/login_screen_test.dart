import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoga_pos_app/api/api_client.dart';

import '../support/fake_backend.dart';
import '../support/harness.dart';

void main() {
  testWidgets('logs in then shows home when a shift is already open (screen 01)', (tester) async {
    final client = ApiClient(client: authBackend(hasOpenShift: true), baseUrl: 'http://test/api/v1');
    await tester.pumpWidget(buildApp(client));

    expect(find.text('Khoga Café'), findsOneWidget); // login shown
    await tester.enterText(find.byKey(const Key('username')), 'cashier01');
    await tester.enterText(find.byKey(const Key('password')), 'Secret@123');
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-button')), findsNothing); // left login
    expect(find.text('Nguyễn Thu Ngân'), findsOneWidget); // home greets the user
  });

  testWidgets('shows the backend error and stays on login for bad credentials', (tester) async {
    final client = ApiClient(client: authBackend(loginFails: true), baseUrl: 'http://test/api/v1');
    await tester.pumpWidget(buildApp(client));

    await tester.enterText(find.byKey(const Key('username')), 'cashier01');
    await tester.enterText(find.byKey(const Key('password')), 'wrong');
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sai tài khoản'), findsOneWidget);
    expect(find.byKey(const Key('login-button')), findsOneWidget); // still on login
  });
}
