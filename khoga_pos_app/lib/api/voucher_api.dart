import 'api_client.dart';
import 'models.dart';

class VoucherApi {
  final ApiClient _client;
  VoucherApi(this._client);

  Future<List<VoucherLite>> listActive() async {
    final data = await _client.get('/vouchers');
    final content = (data is Map<String, dynamic> ? data['content'] as List? : data as List?) ?? const [];
    return content
        .where((e) => (e as Map)['status'] == 'ACTIVE')
        .map((e) => VoucherLite.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
