import 'api_client.dart';
import 'models.dart';

/// Shift session endpoints (UC-44 open, UC-53 close). The cashier must have an
/// open shift before using the POS.
class ShiftApi {
  final ApiClient _client;
  ShiftApi(this._client);

  /// The caller's currently-open shift, or null if none (backend answers 404).
  Future<Shift?> getActive() async {
    try {
      final data = await _client.get('/shifts/active');
      return Shift.fromJson(data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<Shift> open(String posRegisterId, num startingCash) async {
    final data = await _client.post('/shifts/open', {
      'posRegisterId': posRegisterId,
      'startingCash': startingCash,
    });
    return Shift.fromJson(data as Map<String, dynamic>);
  }
}
