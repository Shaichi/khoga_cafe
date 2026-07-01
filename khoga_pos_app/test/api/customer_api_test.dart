import 'package:flutter_test/flutter_test.dart';
import 'package:khoga_pos_app/api/api_client.dart';
import 'package:khoga_pos_app/api/customer_api.dart';

import '../support/fake_backend.dart';

void main() {
  ApiClient client() =>
      ApiClient(client: authBackend(), baseUrl: 'http://test/api/v1')..setToken('jwt-1');

  test('search returns members matching the query', () async {
    final results = await CustomerApi(client()).search('Hội');
    expect(results, isNotEmpty);
    expect(results.first.id, 'cust-1');
    expect(results.first.fullName, contains('Hội'));
    expect(results.first.points, 500);
  });

  test('search returns empty when nothing matches', () async {
    final results = await CustomerApi(client()).search('zzzzz');
    expect(results, isEmpty);
  });
}
