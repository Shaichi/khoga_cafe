import 'api_client.dart';
import 'models.dart';

/// Catalog reads for the POS (UC-15). Categories drive the tabs; menu items fill
/// the product grid.
class MenuApi {
  final ApiClient _client;
  MenuApi(this._client);

  Future<List<Category>> listCategories() async {
    final data = await _client.get('/categories?active=true&size=100');
    return _content(data).map(Category.fromJson).toList();
  }

  Future<List<MenuItem>> listMenuItems({String? categoryId, String? search}) async {
    final qp = <String>['size=200'];
    if (categoryId != null) qp.add('categoryId=$categoryId');
    if (search != null && search.isNotEmpty) qp.add('search=${Uri.encodeQueryComponent(search)}');
    final data = await _client.get('/menu-items?${qp.join('&')}');
    return _content(data).map(MenuItem.fromJson).toList();
  }

  Future<List<Topping>> listToppings(String menuItemId) async {
    final data = await _client.get('/menu-items/$menuItemId/toppings');
    // Assuming backend returns a direct list or a paginated list.
    // If it's a list, data is a List. If it's paginated, it has 'content'.
    if (data is List) {
      return data.cast<Map<String, dynamic>>().map(Topping.fromJson).toList();
    } else if (data is Map && data.containsKey('content')) {
      return _content(data).map(Topping.fromJson).toList();
    }
    return [];
  }

  List<Map<String, dynamic>> _content(dynamic data) {
    final content = (data as Map<String, dynamic>)['content'] as List;
    return content.cast<Map<String, dynamic>>();
  }
}
