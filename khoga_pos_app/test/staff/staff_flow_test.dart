import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoga_pos_app/api/api_client.dart';

import '../support/fake_backend.dart';
import '../support/harness.dart';

Future<void> _login(WidgetTester tester, String username) async {
  await tester.enterText(find.byKey(const Key('username')), username);
  await tester.enterText(find.byKey(const Key('password')), 'Secret@123');
  await tester.tap(find.byKey(const Key('login-button')));
  await tester.pumpAndSettle();
}

void main() {
  // NOTE: 'attendance (31) check-in with PIN' test removed because the UI was replaced by Manager Attendance Report.

  testWidgets('manager: home -> schedule (30) shows shifts + roster', (tester) async {
    final client = ApiClient(
        client: authBackend(role: 'STORE_MANAGER', hasOpenShift: true), baseUrl: 'http://test/api/v1');
    await tester.pumpWidget(buildApp(client));
    await _login(tester, 'manager01');

    expect(find.byKey(const Key('schedule-action')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('schedule-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('schedule-action')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('schedule-view')), findsOneWidget);
    expect(find.byKey(const Key('shift-sc1')), findsOneWidget);
    expect(find.textContaining('Liên chi nhánh'), findsOneWidget);
  });

  testWidgets('cashier home hides the manager schedule entry', (tester) async {
    final client = ApiClient(client: authBackend(hasOpenShift: true), baseUrl: 'http://test/api/v1');
    await tester.pumpWidget(buildApp(client));
    await _login(tester, 'cashier01');
    expect(find.byKey(const Key('schedule-action')), findsNothing);
    expect(find.byKey(const Key('attendance-action')), findsNothing);
  });
}
