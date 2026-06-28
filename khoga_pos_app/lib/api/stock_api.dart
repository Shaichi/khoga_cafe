import 'api_client.dart';
import 'models.dart';

/// Branch stock endpoints (UC-31/32/61). Store Manager scope on the backend.
class StockApi {
  final ApiClient _client;
  StockApi(this._client);

  /// Stock dashboard rows (UC-31), optionally only low-stock items or matching a
  /// name/code search.
  Future<List<StockItem>> list({bool? lowStock, String? search, int page = 0}) async {
    final q = <String>['page=$page'];
    if (lowStock == true) q.add('lowStock=true');
    if (search != null && search.isNotEmpty) q.add('search=${Uri.encodeQueryComponent(search)}');
    final data = await _client.get('/stock?${q.join('&')}');
    final content = (data as Map<String, dynamic>)['content'] as List? ?? const [];
    return content.map((j) => StockItem.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Record a stock delivery (UC-32). Returns the resulting ledger entry.
  Future<StockTransaction> import(String stockItemId, num quantity, {String? note}) async {
    final data = await _client.post('/stock/import', {
      'stockItemId': stockItemId,
      'quantity': quantity,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return StockTransaction.fromJson(data as Map<String, dynamic>);
  }

  /// Stock movement ledger (UC-61), optionally filtered by transaction [type].
  Future<List<StockTransaction>> transactions({String? type, int page = 0}) async {
    final q = <String>['page=$page'];
    if (type != null) q.add('type=$type');
    final data = await _client.get('/stock/transactions?${q.join('&')}');
    final content = (data as Map<String, dynamic>)['content'] as List? ?? const [];
    return content.map((j) => StockTransaction.fromJson(j as Map<String, dynamic>)).toList();
  }
}
