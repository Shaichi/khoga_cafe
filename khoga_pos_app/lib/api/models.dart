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

/// Mirrors com.khoga.pos.dto.DiscountBreakdown (BR-70 stacking pipeline).
class CheckoutBreakdown {
  final num grossSubtotal;
  final num voucherDiscount;
  final num pointDiscount;
  final num taxAmount;
  final num netTotalPayable;
  final int pointsEarned;

  CheckoutBreakdown({
    required this.grossSubtotal,
    required this.voucherDiscount,
    required this.pointDiscount,
    required this.taxAmount,
    required this.netTotalPayable,
    required this.pointsEarned,
  });

  factory CheckoutBreakdown.fromJson(Map<String, dynamic> j) => CheckoutBreakdown(
        grossSubtotal: (j['grossSubtotal'] as num?) ?? 0,
        voucherDiscount: (j['voucherDiscount'] as num?) ?? 0,
        pointDiscount: (j['pointDiscount'] as num?) ?? 0,
        taxAmount: (j['taxAmount'] as num?) ?? 0,
        netTotalPayable: (j['netTotalPayable'] as num?) ?? 0,
        pointsEarned: (j['pointsEarned'] as int?) ?? 0,
      );
}

/// Mirrors com.khoga.pos.dto.CheckoutResponse.
class CheckoutResult {
  final String orderId;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final num changeDue;
  final String? qrContent;
  final CheckoutBreakdown breakdown;

  CheckoutResult({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.changeDue,
    required this.breakdown,
    this.qrContent,
  });

  factory CheckoutResult.fromJson(Map<String, dynamic> j) => CheckoutResult(
        orderId: j['orderId'] as String,
        orderNumber: j['orderNumber'] as String? ?? '',
        status: j['status'] as String? ?? '',
        paymentStatus: j['paymentStatus'] as String? ?? '',
        paymentMethod: j['paymentMethod'] as String? ?? '',
        changeDue: (j['changeDue'] as num?) ?? 0,
        qrContent: j['qrContent'] as String?,
        breakdown: CheckoutBreakdown.fromJson((j['breakdown'] as Map<String, dynamic>?) ?? const {}),
      );
}
