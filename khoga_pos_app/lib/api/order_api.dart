import 'api_client.dart';
import 'models.dart';

/// Order history + detail endpoints (UC-54 history, UC-73 detail). Scoped to the
/// caller's branch by the backend.
class OrderApi {
  final ApiClient _client;
  OrderApi(this._client);

  /// Branch order history, newest first, optionally filtered by [status]
  /// (e.g. 'COMPLETED', 'CANCELLED') or dates. Returns the page's content.
  Future<List<OrderSummary>> history({String? status, DateTime? startDate, DateTime? endDate, int page = 0}) async {
    final q = <String>['page=$page'];
    if (status != null) q.add('status=$status');
    if (startDate != null) q.add('startDate=${startDate.toIso8601String().split('T')[0]}');
    if (endDate != null) q.add('endDate=${endDate.toIso8601String().split('T')[0]}');
    
    final data = await _client.get('/orders?${q.join('&')}');
    final content = (data as Map<String, dynamic>)['content'] as List? ?? const [];
    return content.map((j) => OrderSummary.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Full detail for one order (UC-73).
  Future<OrderDetail> detail(String id) async {
    final data = await _client.get('/orders/$id');
    return OrderDetail.fromJson(data as Map<String, dynamic>);
  }

  /// Live barista queue — active orders, oldest first (UC-57).
  Future<List<OrderSummary>> queue() async {
    final data = await _client.get('/queue');
    return (data as List).map((j) => OrderSummary.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Advance an order to the next state (UC-58); returns the new state plus any
  /// stock warnings raised by recipe deduction (BR-89).
  Future<StatusUpdate> updateStatus(String id, String status) async {
    final data = await _client.post('/orders/$id/status', {'status': status});
    return StatusUpdate.fromJson(data as Map<String, dynamic>);
  }

  /// Cancel a pending order (UC-55). [reason] is the dropdown selection (mandatory),
  /// [notes] is the free-text explanation (mandatory per SRS Table 3-41).
  Future<void> cancel(String id, String reason, {String? notes}) async {
    await _client.post('/orders/$id/cancel', {
      'reason': reason,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
  }

  /// Refund or comp an order (UC-75).
  Future<void> refund(String id, String type, String reason, String smPin) async {
    await _client.post('/orders/$id/refund', {
      'refundType': type,
      'reason': reason,
      'smApprovalPin': smPin,
    });
  }
}
