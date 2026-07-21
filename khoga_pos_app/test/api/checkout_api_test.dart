import 'package:flutter_test/flutter_test.dart';
import 'package:khoga_pos_app/api/api_client.dart';
import 'package:khoga_pos_app/api/checkout_api.dart';
import 'package:khoga_pos_app/api/models.dart';
import 'package:khoga_pos_app/pos/cart_controller.dart';

import '../support/fake_backend.dart';

CartLine _line(String id, num price, int qty) => CartLine(item: MenuItem(id: id, name: id, price: price), qty: qty);

ApiClient _client() => ApiClient(client: authBackend(), baseUrl: 'http://test/api/v1')..setToken('jwt-1');

void main() {
  group('CheckoutApi', () {
    test('preview returns the breakdown net total for the cart', () async {
      final req = CheckoutRequestData(lines: [_line('m1', 30000, 2)], paymentMethod: 'CASH', orderType: 'TAKEAWAY');
      final b = await CheckoutApi(_client()).preview(req);
      expect(b.grossSubtotal, 60000);
      expect(b.netTotalPayable, 60000);
    });

    test('submit (cash) creates the order and returns the change due', () async {
      final req = CheckoutRequestData(
        lines: [_line('m1', 30000, 1)],
        paymentMethod: 'CASH',
        cashReceived: 50000,
        orderType: 'TAKEAWAY',
      );
      final r = await CheckoutApi(_client()).submit(req);
      expect(r.orderNumber, 'ORD-001');
      expect(r.paymentStatus, 'PAID');
      expect(r.changeDue, 20000);
    });

    test('submit (VietQR) returns an awaiting-payment order with a QR code', () async {
      final req = CheckoutRequestData(lines: [_line('m1', 30000, 1)], paymentMethod: 'VIETQR', orderType: 'TAKEAWAY');
      final r = await CheckoutApi(_client()).submit(req);
      expect(r.paymentStatus, 'AWAITING_PAYMENT');
      expect(r.qrContent, isNotNull);
    });
  });
}
