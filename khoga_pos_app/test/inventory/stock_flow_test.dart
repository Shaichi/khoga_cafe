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
    await tester.tap(find.byKey(const Key('stock-row-si1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('import-quantity')), '10');
    await tester.tap(find.byKey(const Key('import-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('import-success')), findsOneWidget);
    expect(find.textContaining('→'), findsOneWidget);

    // Done -> back on the dashboard.
    await tester.tap(find.byKey(const Key('import-done')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stock-list')), findsOneWidget);

    // Ledger reachable.
    await tester.tap(find.byKey(const Key('stock-ledger-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tx-list')), findsOneWidget);
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
