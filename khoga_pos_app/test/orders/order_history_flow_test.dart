import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoga_pos_app/api/api_client.dart';

import '../support/fake_backend.dart';
import '../support/harness.dart';

Future<void> _login(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('username')), 'cashier01');
  await tester.enterText(find.byKey(const Key('password')), 'Secret@123');
  await tester.tap(find.byKey(const Key('login-button')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('home -> order history (49): lists orders, filters, opens detail (40)', (tester) async {
    final client = ApiClient(client: authBackend(hasOpenShift: true), baseUrl: 'http://test/api/v1');
    await tester.pumpWidget(buildApp(client));
    await _login(tester);

    await tester.tap(find.byKey(const Key('order-history-action')));
    await tester.pumpAndSettle();

    // Both orders listed.
    expect(find.byKey(const Key('order-list')), findsOneWidget);
    expect(find.text('ORD-001'), findsOneWidget);
    expect(find.text('ORD-002'), findsOneWidget);

    // Filter to cancelled -> only ORD-002.
    await tester.dragUntilVisible(
      find.byKey(const Key('filter-CANCELLED')),
      find.byType(ListView).first,
      const Offset(-100, 0),
    );
    await tester.pumpAndSettle();
    
    final cancelledChip = find.byKey(const Key('filter-CANCELLED'));
    await tester.tap(cancelledChip);
    await tester.pumpAndSettle();
    expect(find.text('ORD-001'), findsNothing);
    expect(find.text('ORD-002'), findsOneWidget);

    // Back to all, open the first order's detail.
    await tester.dragUntilVisible(
      find.byKey(const Key('filter-ALL')),
      find.byType(ListView).first,
      const Offset(100, 0),
    );
    await tester.pumpAndSettle();
    
    await tester.tap(find.byKey(const Key('filter-ALL')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('order-row-o1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('order-detail')), findsOneWidget);
    expect(find.textContaining('Espresso'), findsOneWidget);
    expect(find.textContaining('Shot thêm'), findsOneWidget);
  });
}
