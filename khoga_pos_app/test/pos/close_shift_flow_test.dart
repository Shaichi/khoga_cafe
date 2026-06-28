import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoga_pos_app/api/api_client.dart';

import '../support/fake_backend.dart';
import '../support/harness.dart';

void main() {
  testWidgets('home -> close shift (41): count cash, see Z-report, finish back to open-shift',
      (tester) async {
    final client = ApiClient(client: authBackend(hasOpenShift: true), baseUrl: 'http://test/api/v1');
    await tester.pumpWidget(buildApp(client));

    // Log in -> lands on home (shift already open).
    await tester.enterText(find.byKey(const Key('username')), 'cashier01');
    await tester.enterText(find.byKey(const Key('password')), 'Secret@123');
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ca đang mở'), findsOneWidget);

    // Open the close-shift screen (41).
    await tester.tap(find.byKey(const Key('close-shift-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('closing-cash')), findsOneWidget);

    // Count the drawer exactly -> close.
    await tester.enterText(find.byKey(const Key('closing-cash')), '1200000');
    await tester.tap(find.byKey(const Key('close-shift-button')));
    await tester.pumpAndSettle();

    // Z-report reconciliation shown, no discrepancy.
    expect(find.byKey(const Key('z-report')), findsOneWidget);
    expect(find.textContaining('Khớp tiền'), findsOneWidget);

    // Finish -> shift cleared, routes back to open-shift (34).
    await tester.tap(find.byKey(const Key('z-report-done')));
    await tester.pumpAndSettle();
    expect(find.text('BẮT ĐẦU CA LÀM'), findsOneWidget);
  });

  testWidgets('close shift surfaces a discrepancy when the drawer is short (41)', (tester) async {
    final client = ApiClient(client: authBackend(hasOpenShift: true), baseUrl: 'http://test/api/v1');
    await tester.pumpWidget(buildApp(client));

    await tester.enterText(find.byKey(const Key('username')), 'cashier01');
    await tester.enterText(find.byKey(const Key('password')), 'Secret@123');
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('close-shift-action')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('closing-cash')), '1150000');
    await tester.tap(find.byKey(const Key('close-shift-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('z-report')), findsOneWidget);
    expect(find.textContaining('Lệch'), findsOneWidget);
  });

  testWidgets('blocks closing when no cash amount is entered (41)', (tester) async {
    final client = ApiClient(client: authBackend(hasOpenShift: true), baseUrl: 'http://test/api/v1');
    await tester.pumpWidget(buildApp(client));

    await tester.enterText(find.byKey(const Key('username')), 'cashier01');
    await tester.enterText(find.byKey(const Key('password')), 'Secret@123');
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('close-shift-action')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('close-shift-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('z-report')), findsNothing);
    expect(find.textContaining('Vui lòng nhập'), findsOneWidget);
  });
}
