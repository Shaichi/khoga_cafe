import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:khoga_pos_app/screens/branch_settings_screen.dart';

void main() {
  testWidgets('Pump BranchSettingsScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: BranchSettingsScreen()));
    expect(find.byType(BranchSettingsScreen), findsOneWidget);
  });
}
