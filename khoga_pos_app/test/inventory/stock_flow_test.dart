import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoga_pos_app/api/api_client.dart';

import '../support/fake_backend.dart';
import '../support/harness.dart';

Future<void> _loginManager(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('username')), 'manager01');
  await tester.enterText(find.byKey(const Key('password')), 'Secret@123');
  await tester.tap(find.byKey(const Key('login-button')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('manager home -> stock (26): low filter, import (32), ledger (29)', (tester) async {
    final client = ApiClient(
        client: authBackend(role: 'STORE_MANAGER', hasOpenShift: true), baseUrl: 'http://test/api/v1');
    await tester.pumpWidget(buildApp(client));
    await _loginManager(tester);

    // Manager-only entry present.
    expect(find.byKey(const Key('inventory-action')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('inventory-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('inventory-action')));
    await tester.pumpAndSettle();

    // Dashboard lists both items; low-stock filter narrows to the one.
    expect(find.byKey(const Key('stock-list')), findsOneWidget);
    expect(find.text('Cà phê hạt'), findsOneWidget);
    expect(find.text('Sữa tươi'), findsOneWidget);
    await tester.tap(find.byKey(const Key('low-stock-filter')));
    await tester.pumpAndSettle();
    expect(find.text('Sữa tươi'), findsNothing);
    expect(find.text('Cà phê hạt'), findsOneWidget);

    // Open import for the low item, record a delivery.
    await tester.tap(find.byKey(const Key('to-import-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('import-item-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cà phê hạt (CF-01)').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('import-quantity-si1')), '10');
    await tester.tap(find.byKey(const Key('import-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('import-success')), findsOneWidget);

    // Done -> back on the dashboard.
    await tester.tap(find.byKey(const Key('import-done')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stock-list')), findsOneWidget);

    // Ledger reachable.
    await tester.tap(find.byKey(const Key('stock-ledger-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tx-list')), findsOneWidget);
  });

  testWidgets('export (28): import screen -> export -> success returns to dashboard', (tester) async {
    final client = ApiClient(
        client: authBackend(role: 'STORE_MANAGER', hasOpenShift: true), baseUrl: 'http://test/api/v1');
    await tester.pumpWidget(buildApp(client));
    await _loginManager(tester);

    await tester.ensureVisible(find.byKey(const Key('inventory-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('inventory-action')));
    await tester.pumpAndSettle();

    // Open the export screen.
    await tester.tap(find.byKey(const Key('to-export-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('export-item-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cà phê hạt (CF-01)').last);
    await tester.pumpAndSettle();

    // Reason is mandatory: submitting without it shows an error.
    await tester.enterText(find.byKey(const Key('export-quantity-si1')), '2');
    await tester.tap(find.byKey(const Key('export-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Bắt buộc'), findsOneWidget);

    // With a reason it succeeds and "Xong" returns all the way to the dashboard.
    await tester.enterText(find.byKey(const Key('export-reason-si1')), 'Hỏng');
    await tester.tap(find.byKey(const Key('export-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('export-success')), findsOneWidget);
    await tester.tap(find.byKey(const Key('export-done')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stock-list')), findsOneWidget);
  });

  testWidgets('audit (28): count items -> discrepancy report -> back to dashboard', (tester) async {
    final client = ApiClient(
        client: authBackend(role: 'STORE_MANAGER', hasOpenShift: true), baseUrl: 'http://test/api/v1');
    await tester.pumpWidget(buildApp(client));
    await _loginManager(tester);

    await tester.ensureVisible(find.byKey(const Key('inventory-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('inventory-action')));
    await tester.pumpAndSettle();

    // Open the audit screen from the dashboard app bar.
    await tester.tap(find.byKey(const Key('stock-audit-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('audit-list')), findsOneWidget);

    // Count both items: si1 short by one, si2 matches.
    await tester.enterText(find.byKey(const Key('audit-count-si1')), '4');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('audit-note-si1')), 'Hao hụt');
    await tester.enterText(find.byKey(const Key('audit-count-si2')), '12');
    await tester.tap(find.byKey(const Key('audit-submit')));
    await tester.pumpAndSettle();

    // Report shows the discrepancy line and the matched line.
    expect(find.byKey(const Key('audit-report')), findsOneWidget);
    expect(find.byKey(const Key('audit-result-si1')), findsOneWidget);
    expect(find.text('-1'), findsOneWidget);
    expect(find.text('Khớp'), findsOneWidget);

    await tester.tap(find.byKey(const Key('audit-done')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stock-list')), findsOneWidget);
  });

  testWidgets('cashier home hides the manager inventory entry', (tester) async {
    final client = ApiClient(client: authBackend(hasOpenShift: true), baseUrl: 'http://test/api/v1');
    await tester.pumpWidget(buildApp(client));
    await tester.enterText(find.byKey(const Key('username')), 'cashier01');
    await tester.enterText(find.byKey(const Key('password')), 'Secret@123');
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inventory-action')), findsNothing);
  });
}
