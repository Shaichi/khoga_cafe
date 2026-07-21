import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:khoga_pos_app/screens/branch_settings_screen.dart';

void main() {
  testWidgets('Find texts', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: BranchSettingsScreen()));
    expect(find.text('Tên chi nhánh *'), findsOneWidget);
    expect(find.text('Khoga Café - Nguyễn Du Branch'), findsOneWidget);
  });
}
