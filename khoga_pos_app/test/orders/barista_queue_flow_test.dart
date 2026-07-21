import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoga_pos_app/api/api_client.dart';
import 'package:khoga_pos_app/api/order_api.dart';

import '../support/fake_backend.dart';
import '../support/harness.dart';

void main() {
  group('OrderApi queue/status', () {
    ApiClient client() =>
        ApiClient(client: authBackend(), baseUrl: 'http://test/api/v1')..setToken('jwt-1');

    test('queue returns active orders oldest-first', () async {
      final q = await OrderApi(client()).queue();
      expect(q, hasLength(2));
      expect(q.first.orderNumber, 'ORD-101');
      expect(q.first.status, 'PENDING');
    });

    test('updateStatus to PREPARING returns the new state + BR-89 stock warning', () async {
      final res = await OrderApi(client()).updateStatus('oq1', 'PREPARING');
      expect(res.status, 'PREPARING');
      expect(res.stockWarnings, isNotEmpty);
    });

    test('updateStatus to READY has no stock warning', () async {
      final res = await OrderApi(client()).updateStatus('oq2', 'READY');
      expect(res.status, 'READY');
      expect(res.stockWarnings, isEmpty);
    });
  });

  testWidgets('home -> barista queue (57): list orders, advance status (58)', (tester) async {
    final client = ApiClient(client: authBackend(hasOpenShift: true), baseUrl: 'http://test/api/v1');
    await tester.pumpWidget(buildApp(client));
    await tester.enterText(find.byKey(const Key('username')), 'cashier01');
    await tester.enterText(find.byKey(const Key('password')), 'Secret@123');
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('queue-action')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('portal-grid')), findsOneWidget);
    expect(find.text('ORD-101'), findsOneWidget);
    expect(find.text('ORD-102'), findsOneWidget);

    // Advance the pending order -> PREPARING, stock warning shown in a snackbar.
    await tester.tap(find.byKey(const Key('portal-advance-oq1-PREPARING')));
    await tester.pump(); // start request
    await tester.pump(); // resolve + snackbar
    expect(find.textContaining('âm kho'), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
