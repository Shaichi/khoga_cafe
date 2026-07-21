import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:khoga_pos_app/api/api_client.dart';
import 'package:khoga_pos_app/api/auth_api.dart';
import 'package:khoga_pos_app/api/shift_api.dart';
import 'package:khoga_pos_app/auth/auth_controller.dart';
import 'package:khoga_pos_app/pos/cart_controller.dart';
import 'package:khoga_pos_app/pos/pos_screen.dart';
import 'package:khoga_pos_app/pos/shift_controller.dart';

import '../support/fake_backend.dart';

Widget _posApp(ApiClient client) => MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: client),
        ChangeNotifierProvider(create: (_) => AuthController(client, AuthApi(client))),
        ChangeNotifierProvider(create: (_) => ShiftController(ShiftApi(client))),
        ChangeNotifierProvider(create: (_) => CartController()),
      ],
      child: const MaterialApp(home: PosScreen()),
    );

void main() {
  testWidgets('loads the menu; adding an item fills the cart + subtotal (screen 35)', (tester) async {
    final client = ApiClient(client: authBackend(), baseUrl: 'http://test/api/v1')..setToken('jwt-1');
    await tester.pumpWidget(_posApp(client));
    await tester.pumpAndSettle();

    expect(find.text('Espresso'), findsOneWidget);
    expect(find.textContaining('Giỏ hàng trống'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-m1')));
    await tester.pumpAndSettle(); // Wait for the dialog to appear

    expect(find.text('Tuỳ chọn cho Espresso'), findsOneWidget);
    
    // Tap Thêm vào giỏ
    await tester.tap(find.text('Thêm vào giỏ'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Giỏ hàng trống'), findsNothing);
    expect(find.byKey(const Key('cart-subtotal')), findsOneWidget);
    expect(find.text('30.000 đ'), findsWidgets);
  });

  testWidgets('category tab filters the item list', (tester) async {
    final client = ApiClient(client: authBackend(), baseUrl: 'http://test/api/v1')..setToken('jwt-1');
    await tester.pumpWidget(_posApp(client));
    await tester.pumpAndSettle();

    expect(find.text('Espresso'), findsOneWidget);

    await tester.tap(find.text('Trà')); // category chip
    await tester.pumpAndSettle();

    expect(find.text('Espresso'), findsNothing);
    
    if (find.text('Không có món phù hợp').evaluate().isNotEmpty) {
      fail('Found "Không có món phù hợp" instead of items');
    }
    
    expect(find.text('Trà đào'), findsOneWidget);
  });
}
