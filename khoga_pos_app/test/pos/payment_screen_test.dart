import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:khoga_pos_app/api/api_client.dart';
import 'package:khoga_pos_app/api/models.dart';
import 'package:khoga_pos_app/pos/cart_controller.dart';
import 'package:khoga_pos_app/pos/payment_screen.dart';

import '../support/fake_backend.dart';

void main() {
  testWidgets('previews total, takes cash, creates the order (screen 38)', (tester) async {
    final client = ApiClient(client: authBackend(), baseUrl: 'http://test/api/v1')..setToken('jwt-1');
    final cart = CartController()..add(MenuItem(id: 'm1', name: 'Espresso', price: 30000));

    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: client),
        ChangeNotifierProvider<CartController>.value(value: cart),
      ],
      child: const MaterialApp(home: PaymentScreen()),
    ));
    await tester.pumpAndSettle();

    // Preview shows the payable total (gross 30.000).
    expect(find.byKey(const Key('payable-total')), findsOneWidget);
    expect(find.text('30.000 VND'), findsWidgets);

    // Enter cash tendered -> change computed.
    await tester.enterText(find.byKey(const Key('cash-received')), '50000');
    await tester.pump();
    expect(find.text('20.000 VND'), findsOneWidget);

    // Confirm -> order created, cart cleared.
    await tester.tap(find.byKey(const Key('confirm-payment')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('order-number')), findsOneWidget);
    expect(find.text('ORD-001'), findsOneWidget);
    expect(cart.isEmpty, isTrue);
  });

  testWidgets('blocks confirm when cash tendered is less than the total', (tester) async {
    final client = ApiClient(client: authBackend(), baseUrl: 'http://test/api/v1')..setToken('jwt-1');
    final cart = CartController()..add(MenuItem(id: 'm1', name: 'Espresso', price: 30000));

    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: client),
        ChangeNotifierProvider<CartController>.value(value: cart),
      ],
      child: const MaterialApp(home: PaymentScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('cash-received')), '10000');
    await tester.tap(find.byKey(const Key('confirm-payment')));
    await tester.pumpAndSettle();

    expect(find.textContaining('chưa đủ'), findsOneWidget);
    expect(find.byKey(const Key('order-number')), findsNothing);
  });
}
