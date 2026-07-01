import 'package:flutter/foundation.dart';

import '../api/models.dart';

/// One line in the cart: a menu item plus its quantity.
class CartLine {
  final MenuItem item;
  int qty;
  CartLine(this.item, this.qty);
  num get lineTotal => item.price * qty;
}

/// Local cart state for the POS (screen 35). Holds the line items plus the
/// optional member (loyalty), voucher code and points-to-redeem that flow into
/// the checkout request (UC-48). Pure client-side until checkout.
class CartController extends ChangeNotifier {
  final Map<String, CartLine> _lines = {};

  CustomerLite? _customer;
  String? _voucherCode;
  int _redeemPoints = 0;

  List<CartLine> get lines => _lines.values.toList(growable: false);
  bool get isEmpty => _lines.isEmpty;
  int get itemCount => _lines.values.fold(0, (sum, l) => sum + l.qty);
  num get subtotal => _lines.values.fold<num>(0, (sum, l) => sum + l.lineTotal);

  CustomerLite? get customer => _customer;
  String? get voucherCode => _voucherCode;
  int get redeemPoints => _redeemPoints;

  /// Attach a member; if it changes, any stale redeem-points is reset.
  void attachCustomer(CustomerLite customer) {
    _customer = customer;
    if (_redeemPoints > customer.points) _redeemPoints = 0;
    notifyListeners();
  }

  void clearCustomer() {
    _customer = null;
    _redeemPoints = 0; // points can only be redeemed by a member
    notifyListeners();
  }

  void applyVoucher(String code) {
    final trimmed = code.trim();
    _voucherCode = trimmed.isEmpty ? null : trimmed.toUpperCase();
    notifyListeners();
  }

  void clearVoucher() {
    _voucherCode = null;
    notifyListeners();
  }

  /// Set points to redeem (clamped to the member's balance; 0 without a member).
  void setRedeemPoints(int points) {
    final max = _customer?.points ?? 0;
    _redeemPoints = points.clamp(0, max);
    notifyListeners();
  }

  void add(MenuItem item) {
    final line = _lines[item.id];
    if (line == null) {
      _lines[item.id] = CartLine(item, 1);
    } else {
      line.qty++;
    }
    notifyListeners();
  }

  void decrement(String itemId) {
    final line = _lines[itemId];
    if (line == null) return;
    if (line.qty > 1) {
      line.qty--;
    } else {
      _lines.remove(itemId);
    }
    notifyListeners();
  }

  void remove(String itemId) {
    if (_lines.remove(itemId) != null) notifyListeners();
  }

  void clear() {
    if (_lines.isEmpty && _customer == null && _voucherCode == null && _redeemPoints == 0) return;
    _lines.clear();
    _customer = null;
    _voucherCode = null;
    _redeemPoints = 0;
    notifyListeners();
  }
}
