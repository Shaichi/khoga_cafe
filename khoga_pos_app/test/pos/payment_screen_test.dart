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

  testWidgets('member + voucher + points reduce the previewed net total (BR-70)', (tester) async {
    final client = ApiClient(client: authBackend(), baseUrl: 'http://test/api/v1')..setToken('jwt-1');
    final cart = CartController()..add(MenuItem(id: 'm1', name: 'Espresso', price: 30000));
    cart.attachCustomer(CustomerLite(id: 'cust-1', fullName: 'Hội Viên', points: 500));
    cart.applyVoucher('GIAM10');   // -10.000
    cart.setRedeemPoints(100);      // -10.000 (100 × 100)

    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: client),
        ChangeNotifierProvider<CartController>.value(value: cart),
      ],
      child: const MaterialApp(home: PaymentScreen()),
    ));
    await tester.pumpAndSettle();

    // 30.000 − 10.000 voucher − 10.000 points = 10.000 net.
    expect(find.text('10.000 VND'), findsWidgets);
  });

  testWidgets('VietQR awaiting screen renders a scannable QR from qrContent', (tester) async {
    final client = ApiClient(client: authBackend(), baseUrl: 'http://test/api/v1')..setToken('jwt-1');
    final cart = CartController()..add(MenuItem(id: 'm1', name: 'Espresso', price: 30000));

    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: client),
        ChangeNotifierProvider<CartController>.value(value: cart),
      ],
      child: const MaterialApp(home: PaymentScreen(pollInterval: Duration(milliseconds: 20))),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('method-VIETQR')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-payment')));
    await tester.pump();
    await tester.pump();

    // Awaiting: the actual QR renders (not the placeholder icon).
    expect(find.byKey(const Key('qr-awaiting')), findsOneWidget);
    expect(find.byKey(const Key('vietqr-image')), findsOneWidget);

    // Let the poll flip to PAID so no timer is left pending at teardown.
    await tester.pump(const Duration(milliseconds: 25));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('qr-awaiting')), findsNothing);
  });

  testWidgets('VietQR creates the order, shows the QR, then polls to a PAID success (38)',
      (tester) async {
    final client = ApiClient(client: authBackend(), baseUrl: 'http://test/api/v1')..setToken('jwt-1');
    final cart = CartController()..add(MenuItem(id: 'm1', name: 'Espresso', price: 30000));

    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: client),
        ChangeNotifierProvider<CartController>.value(value: cart),
      ],
      child: const MaterialApp(home: PaymentScreen(pollInterval: Duration(milliseconds: 20))),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('method-VIETQR')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-payment')));
    await tester.pump(); // submit resolves -> awaiting QR
    await tester.pump();

    // Awaiting state: QR shown, order created, not yet confirmed.
    expect(find.byKey(const Key('qr-awaiting')), findsOneWidget);
    expect(find.textContaining('chờ'), findsWidgets);

    // Advance past the poll interval; the order detail reports PAID.
    await tester.pump(const Duration(milliseconds: 25));
    await tester.pump(); // detail future resolves -> setState to success
    await tester.pump();

    expect(find.byKey(const Key('qr-awaiting')), findsNothing);
    expect(find.byKey(const Key('order-number')), findsOneWidget);
    expect(find.textContaining('Đã thanh toán'), findsOneWidget);
    expect(cart.isEmpty, isTrue);
  });
}
