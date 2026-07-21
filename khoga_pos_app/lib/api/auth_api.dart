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

  /// Self-service profile edit (UC-08): only contact fields are editable.
  Future<Profile> updateProfile({String? email, String? phone}) async {
    final data = await _client.put('/profile', {'email': email, 'phone': phone});
    return Profile.fromJson(data as Map<String, dynamic>);
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _client.post('/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<void> forgotPassword(String email) async {
    await _client.post('/auth/forgot-password', {'email': email});
  }

  Future<void> verifyOtp(String email, String otp) async {
    await _client.post('/auth/verify-otp', {'email': email, 'otp': otp});
  }

  Future<void> resetPassword(String email, String otp, String newPassword) async {
    await _client.post('/auth/reset-password', {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    });
  }

  Future<LoginResponse> forcePasswordChange(String newPassword) async {
    final data = await _client.post('/auth/force-password-change', {
      'newPassword': newPassword,
    });
    return LoginResponse.fromJson(data as Map<String, dynamic>);
  }
}
