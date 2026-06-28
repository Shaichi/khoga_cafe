import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/auth_api.dart';
import '../api/models.dart';

/// Holds the authenticated session for the app. On [login] it stores the JWT on
/// the shared [ApiClient] (so every later request is authorized) and loads the
/// caller's profile. UI observes [isAuthenticated] to switch between login/home.
class AuthController extends ChangeNotifier {
  final ApiClient _apiClient;
  final AuthApi _authApi;

  AuthController(this._apiClient, this._authApi);

  Profile? _profile;
  bool _mustChangePassword = false;

  Profile? get profile => _profile;
  bool get isAuthenticated => _profile != null;
  bool get mustChangePassword => _mustChangePassword;

  Future<void> login(String username, String password) async {
    final res = await _authApi.login(username, password);
    _apiClient.setToken(res.token);
    _mustChangePassword = res.mustChangePassword;
    _profile = await _authApi.getProfile();
    notifyListeners();
  }

  /// Update editable contact fields (UC-08) and refresh the cached profile.
  Future<void> updateProfile({String? email, String? phone}) async {
    _profile = await _authApi.updateProfile(email: email, phone: phone);
    notifyListeners();
  }

  /// Change the signed-in user's password (UC-06).
  Future<void> changePassword(String currentPassword, String newPassword) =>
      _authApi.changePassword(currentPassword, newPassword);

  void logout() {
    _apiClient.setToken(null);
    _profile = null;
    _mustChangePassword = false;
    notifyListeners();
  }
}
