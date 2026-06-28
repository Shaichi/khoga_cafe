import 'package:flutter_test/flutter_test.dart';
import 'package:khoga_pos_app/api/api_client.dart';
import 'package:khoga_pos_app/api/shift_api.dart';

import '../support/fake_backend.dart';

ApiClient _client({bool hasOpenShift = false}) =>
    ApiClient(client: authBackend(hasOpenShift: hasOpenShift), baseUrl: 'http://test/api/v1')..setToken('jwt-1');

void main() {
  group('ShiftApi', () {
    test('getActive returns null when the backend reports no open shift (404)', () async {
      expect(await ShiftApi(_client(hasOpenShift: false)).getActive(), isNull);
    });

    test('getActive returns the open shift when one exists', () async {
      final s = await ShiftApi(_client(hasOpenShift: true)).getActive();
      expect(s, isNotNull);
      expect(s!.posRegisterId, 'POS-01');
      expect(s.status, 'OPEN');
    });

    test('open posts the register + starting cash and returns the shift', () async {
      final s = await ShiftApi(_client()).open('POS-09', 500000);
      expect(s.posRegisterId, 'POS-09');
      expect(s.startingCash, 500000);
      expect(s.status, 'OPEN');
    });

    test('close posts the counted cash and returns the Z-report reconciliation', () async {
      final z = await ShiftApi(_client(hasOpenShift: true)).close('shift-1', 1200000);
      expect(z.expectedCash, 1200000); // opening 1.000.000 + cash sales 200.000
      expect(z.closingCash, 1200000);
      expect(z.discrepancy, 0);
      expect(z.discrepancyFlagged, isFalse);
    });

    test('close flags a discrepancy when counted cash differs from expected', () async {
      final z = await ShiftApi(_client(hasOpenShift: true)).close('shift-1', 1150000);
      expect(z.discrepancy, -50000);
      expect(z.discrepancyFlagged, isTrue);
    });
  });
}
