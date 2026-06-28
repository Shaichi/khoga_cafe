/// Mirrors com.khoga.auth.dto.LoginResponse.
class LoginResponse {
  final String token;
  final String role;
  final bool mustChangePassword;

  LoginResponse({required this.token, required this.role, required this.mustChangePassword});

  factory LoginResponse.fromJson(Map<String, dynamic> j) => LoginResponse(
        token: j['token'] as String,
        role: j['role'] as String,
        mustChangePassword: j['mustChangePassword'] as bool? ?? false,
      );
}

/// Mirrors com.khoga.auth.dto.ProfileResponse.
class Profile {
  final String id;
  final String username;
  final String fullName;
  final String role;
  final String? email;
  final String? phone;
  final String? storeId;

  Profile({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.email,
    this.phone,
    this.storeId,
  });

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        username: j['username'] as String,
        fullName: j['fullName'] as String,
        role: j['role'] as String,
        email: j['email'] as String?,
        phone: j['phone'] as String?,
        storeId: j['storeId'] as String?,
      );
}
