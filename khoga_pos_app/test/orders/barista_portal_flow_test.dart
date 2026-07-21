import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoga_pos_app/api/api_client.dart';

import '../support/fake_backend.dart';
import '../support/harness.dart';

Future<void> _loginBarista(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('username')), 'barista01');
  await tester.enterText(find.byKey(const Key('password')), 'Secret@123');
  await tester.tap(find.byKey(const Key('login-button')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('barista login lands on the landscape portal (57), bypassing the shift gate', (tester) async {
    // No open shift: a cashier would be sent to OpenShiftScreen — the barista must not be.
    final client = ApiClient(client: authBackend(role: 'BARISTA'), baseUrl: 'http://test/api/v1');
    await tester.pumpWidget(buildApp(client));
    await _loginBarista(tester);

    // Straight to the portal — no register/open-shift prompt, no staff Home.
    expect(find.byKey(const Key('portal-grid')), findsOneWidget);
    expect(find.byKey(const Key('register')), findsNothing); // open-shift field absent
    expect(find.textContaining('Lê Pha Chế'), findsOneWidget); // barista identity in the app bar
    expect(find.text('ORD-101'), findsOneWidget);
    expect(find.text('ORD-102'), findsOneWidget);
  });

  testWidgets('barista advances an order; BR-89 stock warning shows in a snackbar', (tester) async {
    final client = ApiClient(client: authBackend(role: 'BARISTA'), baseUrl: 'http://test/api/v1');
    await tester.pumpWidget(buildApp(client));
    await _loginBarista(tester);

    await tester.tap(find.byKey(const Key('portal-advance-oq1-PREPARING')));
    await tester.pump(); // start request
    await tester.pump(); // resolve + snackbar
    expect(find.textContaining('âm kho'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('barista can log out from the portal', (tester) async {
    final client = ApiClient(client: authBackend(role: 'BARISTA'), baseUrl: 'http://test/api/v1');
    await tester.pumpWidget(buildApp(client));
    await _loginBarista(tester);

    expect(find.byKey(const Key('portal-grid')), findsOneWidget);
    await tester.tap(find.byKey(const Key('portal-logout')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-button')), findsOneWidget);
  });
}
