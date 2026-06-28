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
  });
}
