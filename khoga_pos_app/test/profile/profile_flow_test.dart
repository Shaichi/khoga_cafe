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
  testWidgets('home -> profile (07): edit contact, save (08)', (tester) async {
    final client = ApiClient(client: authBackend(hasOpenShift: true), baseUrl: 'http://test/api/v1');
    await tester.pumpWidget(buildApp(client));
    await _login(tester);

    await tester.tap(find.byKey(const Key('profile-action')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile-name')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('profile-email')), 'me@khoga.vn');
    await tester.enterText(find.byKey(const Key('profile-phone')), '0911222333');
    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-saved')), findsOneWidget);
  });

  testWidgets('profile -> change password (06): mismatch blocks, then succeeds', (tester) async {
    final client = ApiClient(client: authBackend(hasOpenShift: true), baseUrl: 'http://test/api/v1');
    await tester.pumpWidget(buildApp(client));
    await _login(tester);

    await tester.tap(find.byKey(const Key('profile-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('change-password-action')));
    await tester.pumpAndSettle();

    // Confirmation mismatch -> blocked.
    await tester.enterText(find.byKey(const Key('current-password')), 'Admin@123');
    await tester.enterText(find.byKey(const Key('new-password')), 'NewPass@123');
    await tester.enterText(find.byKey(const Key('confirm-password')), 'Different@123');
    await tester.tap(find.byKey(const Key('change-pw-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('change-pw-error')), findsOneWidget);
    expect(find.byKey(const Key('change-pw-success')), findsNothing);

    // Matching -> success.
    await tester.enterText(find.byKey(const Key('confirm-password')), 'NewPass@123');
    await tester.tap(find.byKey(const Key('change-pw-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('change-pw-success')), findsOneWidget);
  });
}
