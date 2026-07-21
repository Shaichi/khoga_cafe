import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:khoga_pos_app/api/api_client.dart';
import 'package:khoga_pos_app/api/auth_api.dart';
import 'package:khoga_pos_app/api/models.dart';
import 'package:khoga_pos_app/api/shift_api.dart';
import 'package:khoga_pos_app/auth/auth_controller.dart';
import 'package:khoga_pos_app/pos/cart_controller.dart';
import 'package:khoga_pos_app/pos/pos_screen.dart';
import 'package:khoga_pos_app/pos/shift_controller.dart';

import '../support/fake_backend.dart';

Widget _posApp(ApiClient client, CartController cart) => MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: client),
        ChangeNotifierProvider<CartController>.value(value: cart),
        ChangeNotifierProvider(create: (_) => ShiftController(ShiftApi(client))),
        ChangeNotifierProvider(create: (_) => AuthController(client, AuthApi(client))),
      ],
      child: const MaterialApp(home: PosScreen()),
    );

void main() {
  testWidgets('attach a member via the search sheet, then apply a voucher (screen 35)', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final client = ApiClient(client: authBackend(), baseUrl: 'http://test/api/v1')..setToken('jwt-1');
    final cart = CartController()..add(MenuItem(id: 'm1', name: 'Espresso', price: 30000));

    await tester.pumpWidget(_posApp(client, cart));
    await tester.pumpAndSettle();

    // --- Member: open sheet, search, pick ---
    await tester.tap(find.byKey(const Key('member-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('member-search')), 'Hội');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('member-result-cust-1')));
    await tester.pumpAndSettle();

    expect(cart.customer?.id, 'cust-1');
    expect(find.byKey(const Key('member-chip')), findsOneWidget);

    // --- Voucher and Points: open dialog, enter code, apply ---
    await tester.tap(find.byKey(const Key('voucher-button')));
    await tester.pumpAndSettle();

    // Redeem-points field appears for a member with a balance.
    await tester.ensureVisible(find.byKey(const Key('redeem-points-input')));
    await tester.enterText(find.byKey(const Key('redeem-points-input')), '100');
    await tester.enterText(find.byKey(const Key('voucher-input')), 'giam10');
    
    await tester.tap(find.byKey(const Key('promo-apply')));
    await tester.pumpAndSettle();

    expect(cart.redeemPoints, 100);
    expect(cart.voucherCode, 'GIAM10');
    expect(find.byKey(const Key('voucher-chip')), findsOneWidget);

    // --- Remove both ---
    await tester.tap(find.byKey(const Key('member-remove')));
    await tester.pump();
    expect(cart.customer, isNull);
    expect(cart.redeemPoints, 0);

    await tester.tap(find.byKey(const Key('voucher-remove')));
    await tester.pump();
    expect(cart.voucherCode, isNull);
  });
}
