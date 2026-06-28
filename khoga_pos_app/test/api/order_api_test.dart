import 'package:flutter_test/flutter_test.dart';
import 'package:khoga_pos_app/api/api_client.dart';
import 'package:khoga_pos_app/api/order_api.dart';

import '../support/fake_backend.dart';

ApiClient _client() =>
    ApiClient(client: authBackend(), baseUrl: 'http://test/api/v1')..setToken('jwt-1');

void main() {
  group('OrderApi', () {
    test('history returns the branch orders newest-first', () async {
      final orders = await OrderApi(_client()).history();
      expect(orders, hasLength(2));
      expect(orders.first.orderNumber, 'ORD-001');
      expect(orders.first.itemCount, 2);
      expect(orders.first.total, 50000);
    });

    test('history filters by status', () async {
      final orders = await OrderApi(_client()).history(status: 'CANCELLED');
      expect(orders, hasLength(1));
      expect(orders.single.status, 'CANCELLED');
    });

    test('detail returns the full order with line items + toppings', () async {
      final o = await OrderApi(_client()).detail('o1');
      expect(o.orderNumber, 'ORD-001');
      expect(o.items, hasLength(2));
      expect(o.items.first.menuItemName, 'Espresso');
      expect(o.items.first.toppings.single.name, 'Shot thêm');
      // line total = 30.000 + 1×5.000 topping
      expect(o.items.first.lineTotal, 35000);
      expect(o.total, 50000);
    });
  });
}
