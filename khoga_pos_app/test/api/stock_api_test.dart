import 'package:flutter_test/flutter_test.dart';
import 'package:khoga_pos_app/api/api_client.dart';
import 'package:khoga_pos_app/api/stock_api.dart';

import '../support/fake_backend.dart';

ApiClient _client() =>
    ApiClient(client: authBackend(role: 'STORE_MANAGER'), baseUrl: 'http://test/api/v1')..setToken('jwt-1');

void main() {
  group('StockApi', () {
    test('list returns all branch stock items', () async {
      final items = await StockApi(_client()).list();
      expect(items, hasLength(2));
      expect(items.first.name, 'Cà phê hạt');
      expect(items.first.lowStock, isTrue);
    });

    test('list with lowStock returns only the low items', () async {
      final items = await StockApi(_client()).list(lowStock: true);
      expect(items, hasLength(1));
      expect(items.single.lowStock, isTrue);
    });

    test('list with search filters by name', () async {
      final items = await StockApi(_client()).list(search: 'sữa');
      expect(items, hasLength(1));
      expect(items.single.name, 'Sữa tươi');
    });

    test('import records a delivery and returns the updated ledger entry', () async {
      final tx = await StockApi(_client()).import('si1', 10, note: 'Nhập hàng');
      expect(tx.transactionType, 'IMPORT');
      expect(tx.quantityBefore, 2);
      expect(tx.quantityAfter, 12);
    });

    test('export records a withdrawal and returns the ledger entry', () async {
      final tx = await StockApi(_client()).export('si2', 4, 'Hỏng');
      expect(tx.transactionType, 'EXPORT');
      expect(tx.quantity, -4);
      expect(tx.quantityBefore, 12);
      expect(tx.quantityAfter, 8);
      expect(tx.reason, 'Hỏng');
    });

    test('audit returns the per-item discrepancy report', () async {
      final results = await StockApi(_client()).audit([
        {'stockItemId': 'si1', 'actualQuantity': 4},
        {'stockItemId': 'si2', 'actualQuantity': 12},
      ]);
      expect(results, hasLength(2));
      final coffee = results.firstWhere((r) => r.stockItemId == 'si1');
      expect(coffee.systemQuantity, 5);
      expect(coffee.actualQuantity, 4);
      expect(coffee.adjustment, -1);
      final milk = results.firstWhere((r) => r.stockItemId == 'si2');
      expect(milk.adjustment, 0);
    });

    test('transactions returns the ledger, filterable by type', () async {
      final all = await StockApi(_client()).transactions();
      expect(all, hasLength(2));
      final imports = await StockApi(_client()).transactions(type: 'IMPORT');
      expect(imports, hasLength(1));
      expect(imports.single.transactionType, 'IMPORT');
    });
  });
}
