import 'package:flutter_test/flutter_test.dart';
import 'package:khoga_pos_app/api/api_client.dart';
import 'package:khoga_pos_app/api/menu_api.dart';

import '../support/fake_backend.dart';

ApiClient _client() => ApiClient(client: authBackend(), baseUrl: 'http://test/api/v1')..setToken('jwt-1');

void main() {
  group('MenuApi', () {
    test('listCategories returns the category tabs', () async {
      final cats = await MenuApi(_client()).listCategories();
      expect(cats.map((c) => c.name), containsAll(<String>['Cà phê', 'Trà']));
    });

    test('listMenuItems returns all items with prices', () async {
      final items = await MenuApi(_client()).listMenuItems();
      expect(items.length, 3);
      expect(items.firstWhere((i) => i.name == 'Espresso').price, 30000);
    });

    test('listMenuItems filters by category', () async {
      final items = await MenuApi(_client()).listMenuItems(categoryId: 'c2');
      expect(items.map((i) => i.name), <String>['Trà đào']);
    });
  });
}
