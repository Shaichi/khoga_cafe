import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khoga_pos_app/api/api_client.dart';
import 'package:khoga_pos_app/api/staff_api.dart';

import '../support/fake_backend.dart';
import '../support/harness.dart';

Future<void> _loginManager(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('username')), 'manager01');
  await tester.enterText(find.byKey(const Key('password')), 'Secret@123');
  await tester.tap(find.byKey(const Key('login-button')));
  await tester.pumpAndSettle();
}

Future<void> _openSchedule(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('schedule-action')));
  await tester.pumpAndSettle();
}

void main() {
  group('ScheduleApi create/update', () {
    ApiClient client() =>
        ApiClient(client: authBackend(role: 'STORE_MANAGER'), baseUrl: 'http://test/api/v1')..setToken('jwt-1');

    test('create posts the shift and returns it', () async {
      final s = await ScheduleApi(client()).create(
        employeeId: 'u2',
        shiftDate: '2026-06-30',
        shiftType: 'AFTERNOON',
        shiftStartTime: '12:00',
        shiftEndTime: '18:00',
      );
      expect(s.employeeName, 'Lê Pha Chế');
      expect(s.shiftType, 'AFTERNOON');
      expect(s.shiftStartTime, '12:00');
    });

    test('update edits times for an existing shift', () async {
      final s = await ScheduleApi(client()).update('sc1',
          shiftType: 'FULL_DAY', shiftStartTime: '07:00', shiftEndTime: '19:00');
      expect(s.id, 'sc1');
      expect(s.shiftType, 'FULL_DAY');
      expect(s.shiftEndTime, '19:00');
    });
  });

  testWidgets('manager: schedule (30) -> add shift (36)', (tester) async {
    final client = ApiClient(
        client: authBackend(role: 'STORE_MANAGER', hasOpenShift: true), baseUrl: 'http://test/api/v1');
    await tester.pumpWidget(buildApp(client));
    await _loginManager(tester);
    await tester.ensureVisible(find.byKey(const Key('schedule-action')));
    await tester.pumpAndSettle();
    await _openSchedule(tester);

    await tester.tap(find.byKey(const Key('schedule-add')));
    await tester.pumpAndSettle();

    // Pick employee, fill date + times, save.
    await tester.tap(find.byKey(const Key('emp-u2')));
    await tester.enterText(find.byKey(const Key('shift-date')), '2026-06-30');
    await tester.tap(find.byKey(const Key('type-AFTERNOON')));
    await tester.enterText(find.byKey(const Key('shift-start')), '12:00');
    await tester.enterText(find.byKey(const Key('shift-end')), '18:00');
    await tester.ensureVisible(find.byKey(const Key('schedule-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('schedule-save')));
    await tester.pumpAndSettle();

    // Back on the schedule view (form popped).
    expect(find.byKey(const Key('schedule-view')), findsOneWidget);
  });

  testWidgets('manager: schedule (30) -> edit shift (37) keeps employee fixed', (tester) async {
    final client = ApiClient(
        client: authBackend(role: 'STORE_MANAGER', hasOpenShift: true), baseUrl: 'http://test/api/v1');
    await tester.pumpWidget(buildApp(client));
    await _loginManager(tester);
    await tester.ensureVisible(find.byKey(const Key('schedule-action')));
    await tester.pumpAndSettle();
    await _openSchedule(tester);

    await tester.tap(find.byKey(const Key('shift-sc1')));
    await tester.pumpAndSettle();

    // Employee field is read-only text (no chooser); date is prefilled.
    expect(find.byKey(const Key('emp-u1')), findsNothing);
    await tester.tap(find.byKey(const Key('type-FULL_DAY')));
    await tester.enterText(find.byKey(const Key('shift-end')), '19:00');
    await tester.ensureVisible(find.byKey(const Key('schedule-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('schedule-save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('schedule-view')), findsOneWidget);
  });
}
