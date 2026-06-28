import 'api_client.dart';
import 'models.dart';

/// Order history + detail endpoints (UC-54 history, UC-73 detail). Scoped to the
/// caller's branch by the backend.
class OrderApi {
  final ApiClient _client;
  OrderApi(this._client);

  /// Branch order history, newest first, optionally filtered by [status]
  /// (e.g. 'COMPLETED', 'CANCELLED'). Returns the page's content.
  Future<List<OrderSummary>> history({String? status, int page = 0}) async {
    final q = <String>['page=$page'];
    if (status != null) q.add('status=$status');
    final data = await _client.get('/orders?${q.join('&')}');
    final content = (data as Map<String, dynamic>)['content'] as List? ?? const [];
    return content.map((j) => OrderSummary.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Full detail for one order (UC-73).
  Future<OrderDetail> detail(String id) async {
    final data = await _client.get('/orders/$id');
    return OrderDetail.fromJson(data as Map<String, dynamic>);
  }
}
