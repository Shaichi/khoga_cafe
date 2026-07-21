import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:khoga_pos_app/screens/branch_settings_screen.dart';

void main() {
  testWidgets('Pump BranchSettingsScreen small', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(300, 400);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: BranchSettingsScreen())));
    expect(find.byType(BranchSettingsScreen), findsOneWidget);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
