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

/// Mirrors com.khoga.pos.dto.ShiftResponse (status is "OPEN" / "CLOSED").
class Shift {
  final String id;
  final String posRegisterId;
  final num startingCash;
  final String status;

  Shift({required this.id, required this.posRegisterId, required this.startingCash, required this.status});

  factory Shift.fromJson(Map<String, dynamic> j) => Shift(
        id: j['id'] as String,
        posRegisterId: j['posRegisterId'] as String? ?? '',
        startingCash: (j['startingCash'] as num?) ?? 0,
        status: j['status'] as String? ?? 'OPEN',
      );
}

/// Mirrors com.khoga.catalog.dto.CategoryResponse (subset).
class Category {
  final String id;
  final String name;
  Category({required this.id, required this.name});
  factory Category.fromJson(Map<String, dynamic> j) =>
      Category(id: j['id'] as String, name: j['name'] as String);
}

/// Mirrors com.khoga.catalog.dto.MenuItemResponse (subset used by the POS).
class MenuItem {
  final String id;
  final String name;
  final num price;
  final String? categoryId;
  final String? categoryName;

  MenuItem({required this.id, required this.name, required this.price, this.categoryId, this.categoryName});

  factory MenuItem.fromJson(Map<String, dynamic> j) => MenuItem(
        id: j['id'] as String,
        name: j['name'] as String,
        price: (j['price'] as num?) ?? 0,
        categoryId: j['categoryId'] as String?,
        categoryName: j['categoryName'] as String?,
      );
}
