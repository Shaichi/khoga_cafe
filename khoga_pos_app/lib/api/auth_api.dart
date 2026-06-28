import 'api_client.dart';
import 'models.dart';

/// Auth endpoints (UC-01/06/09). The mobile app authenticates with the JWT
/// returned in the login body, sent thereafter as a Bearer header.
class AuthApi {
  final ApiClient _client;
  AuthApi(this._client);

  Future<LoginResponse> login(String username, String password) async {
    final data = await _client.post('/auth/login', {'username': username, 'password': password});
    return LoginResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<Profile> getProfile() async {
    final data = await _client.get('/profile');
    return Profile.fromJson(data as Map<String, dynamic>);
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _client.post('/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}
