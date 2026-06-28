import 'package:flutter_test/flutter_test.dart';
import 'package:khoga_pos_app/api/api_client.dart';
import 'package:khoga_pos_app/api/staff_api.dart';

import '../support/fake_backend.dart';

ApiClient _client({String role = 'CASHIER'}) =>
    ApiClient(client: authBackend(role: role), baseUrl: 'http://test/api/v1')..setToken('jwt-1');

void main() {
  group('ScheduleApi', () {
    test('list returns the scheduled shifts', () async {
      final shifts = await ScheduleApi(_client(role: 'STORE_MANAGER')).list();
      expect(shifts, hasLength(2));
      expect(shifts.first.employeeName, 'Nguyễn Thu Ngân');
      expect(shifts.first.shiftType, 'MORNING');
      expect(shifts[1].crossBranch, isTrue);
    });

    test('roster returns branch staff with PIN status', () async {
      final roster = await ScheduleApi(_client(role: 'STORE_MANAGER')).roster();
      expect(roster, hasLength(2));
      expect(roster.first.pinSet, isTrue);
      expect(roster[1].pinSet, isFalse);
    });
  });

  group('AttendanceApi', () {
    test('checkIn with a valid PIN returns the pairing', () async {
      final a = await AttendanceApi(_client()).checkIn('1234', photoUrl: 'http://x/p.jpg');
      expect(a.status, 'PRESENT');
      expect(a.checkInAt, isNotNull);
      expect(a.pendingVerification, isFalse);
    });

    test('checkIn without a photo flags pending verification', () async {
      final a = await AttendanceApi(_client()).checkIn('1234');
      expect(a.pendingVerification, isTrue);
    });

    test('checkIn with a wrong PIN throws', () async {
      expect(() => AttendanceApi(_client()).checkIn('0000'), throwsA(isA<ApiException>()));
    });

    test('checkOut closes the pairing', () async {
      final a = await AttendanceApi(_client()).checkOut('1234');
      expect(a.checkOutAt, isNotNull);
    });
  });
}
