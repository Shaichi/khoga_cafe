import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoga_pos_app/api/api_client.dart';

import '../support/fake_backend.dart';
import '../support/harness.dart';

void main() {
  testWidgets('login with no open shift routes to open-shift (34), then opening unlocks home',
      (tester) async {
    final client = ApiClient(client: authBackend(hasOpenShift: false), baseUrl: 'http://test/api/v1');
    await tester.pumpWidget(buildApp(client));

    // Log in.
    await tester.enterText(find.byKey(const Key('username')), 'cashier01');
    await tester.enterText(find.byKey(const Key('password')), 'Secret@123');
    await tester.tap(find.byKey(const Key('login-button')));
    await tester.pumpAndSettle();

    // All users now route to home first.
    expect(find.text('Nguyễn Thu Ngân'), findsOneWidget);

    // Tap POS action. Since there is no open shift, it routes to open-shift (34).
    await tester.tap(find.byKey(const Key('pos-action')));
    await tester.pumpAndSettle();

    expect(find.text('BẮT ĐẦU CA LÀM'), findsOneWidget);
    expect(find.byKey(const Key('starting-cash')), findsOneWidget);

    await tester.tap(find.byKey(const Key('register')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('POS-01').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-shift-button')));
    await tester.pumpAndSettle();

    // Confirm dialog
    await tester.tap(find.text('ĐỒNG Ý'));
    await tester.pumpAndSettle();

    // Shift opened -> routes to POS Checkout Grid (35).
    expect(find.text('Giỏ Hàng Thanh Toán'), findsOneWidget);
  });
}
