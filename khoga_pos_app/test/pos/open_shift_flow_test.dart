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

    // No active shift -> open-shift screen (34).
    expect(find.text('BẮT ĐẦU CA LÀM'), findsOneWidget);
    expect(find.byKey(const Key('starting-cash')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('register')), 'POS-01');
    await tester.tap(find.byKey(const Key('open-shift-button')));
    await tester.pumpAndSettle();

    // Shift opened -> POS home.
    expect(find.text('Nguyễn Thu Ngân'), findsOneWidget);
    expect(find.textContaining('Ca đang mở'), findsOneWidget);
  });
}
