import 'api_client.dart';
import 'models.dart';

/// Customer lookup for attaching a member to a POS order (UC-25/48). Read-only
/// from the POS; full CRM lives in the web admin.
class CustomerApi {
  final ApiClient _client;
  CustomerApi(this._client);

  /// Search members by name/phone. Returns the page content as [CustomerLite].
  Future<List<CustomerLite>> search(String query) async {
    final q = Uri.encodeQueryComponent(query);
    final data = await _client.get('/customers?search=$q');
    final content = (data is Map<String, dynamic> ? data['content'] as List? : data as List?) ?? const [];
    return content.map((e) => CustomerLite.fromJson(e as Map<String, dynamic>)).toList();
  }
}
