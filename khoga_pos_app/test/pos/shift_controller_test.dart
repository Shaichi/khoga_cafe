import 'package:flutter_test/flutter_test.dart';
import 'package:khoga_pos_app/api/api_client.dart';
import 'package:khoga_pos_app/api/shift_api.dart';
import 'package:khoga_pos_app/pos/shift_controller.dart';

import '../support/fake_backend.dart';

ShiftController _controller({bool hasOpenShift = false}) {
  final client = ApiClient(client: authBackend(hasOpenShift: hasOpenShift), baseUrl: 'http://test/api/v1')
    ..setToken('jwt-1');
  return ShiftController(ShiftApi(client));
}

void main() {
  test('loadActive with no open shift leaves the POS gate closed', () async {
    final c = _controller(hasOpenShift: false);
    await c.loadActive();
    expect(c.loaded, isTrue);
    expect(c.hasOpenShift, isFalse);
  });

  test('loadActive surfaces an already-open shift', () async {
    final c = _controller(hasOpenShift: true);
    await c.loadActive();
    expect(c.hasOpenShift, isTrue);
    expect(c.active!.posRegisterId, 'POS-01');
  });

  test('open sets the active shift', () async {
    final c = _controller();
    await c.open('POS-01', 1000000);
    expect(c.hasOpenShift, isTrue);
    expect(c.active!.posRegisterId, 'POS-01');
  });
}
