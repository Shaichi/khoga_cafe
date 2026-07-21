import 'package:flutter/foundation.dart';

import '../api/models.dart';

class CartTopping {
  final String id;
  final String name;
  final num price;
  int qty;

  CartTopping({required this.id, required this.name, required this.price, this.qty = 1});
}

/// One line in the cart: a menu item plus its toppings and quantity.
class CartLine {
  final String id;
  final MenuItem item;
  final List<CartTopping> toppings;
  int qty;

  CartLine({
    String? id,
    required this.item,
    required this.qty,
    this.toppings = const [],
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  num get unitTotal => item.price + toppings.fold<num>(0, (sum, t) => sum + (t.price * t.qty));
  num get lineTotal => unitTotal * qty;
  
  bool hasSameContent(MenuItem otherItem, List<CartTopping> otherToppings) {
    if (item.id != otherItem.id) return false;
    if (toppings.length != otherToppings.length) return false;
    for (final t in toppings) {
      final match = otherToppings.where((ot) => ot.id == t.id && ot.qty == t.qty);
      if (match.isEmpty) return false;
    }
    return true;
  }
}

/// Local cart state for the POS (screen 35). Holds the line items plus the
/// optional member (loyalty), voucher and points-to-redeem that flow into
/// the checkout request (UC-48).
class CartController extends ChangeNotifier {
  final List<CartLine> _lines = [];

  CustomerLite? _customer;
  VoucherLite? _voucher;
  int _redeemPoints = 0;
  String _orderType = 'TAKEAWAY';

  List<CartLine> get lines => List.unmodifiable(_lines);
  bool get isEmpty => _lines.isEmpty;
  int get itemCount => _lines.fold(0, (sum, l) => sum + l.qty);
  num get subtotal => _lines.fold<num>(0, (sum, l) => sum + l.lineTotal);

  CustomerLite? get customer => _customer;
  VoucherLite? get voucher => _voucher;
  String? get voucherCode => _voucher?.code;
  int get redeemPoints => _redeemPoints;
  String get orderType => _orderType;

  num get voucherDiscount {
    if (_voucher == null) return 0;
    num discount = 0;
    if (_voucher!.discountType == "PERCENTAGE") {
      discount = subtotal * (_voucher!.discountValue / 100);
    } else {
      discount = _voucher!.discountValue;
    }
    return discount > subtotal ? subtotal : discount;
  }

  num get pointDiscount {
    // BR: 1 point = 100 VND
    return _redeemPoints * 100;
  }

  num get totalDiscount => voucherDiscount + pointDiscount;

  num get netTotal {
    final net = subtotal - totalDiscount;
    return net < 0 ? 0 : net;
  }

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

  void applyVoucher(VoucherLite voucher) {
    _voucher = voucher;
    notifyListeners();
  }

  void clearVoucher() {
    _voucher = null;
    notifyListeners();
  }

  /// Set points to redeem (clamped to the member's balance; 0 without a member).
  void setRedeemPoints(int points) {
    final max = _customer?.points ?? 0;
    _redeemPoints = points.clamp(0, max);
    notifyListeners();
  }

  void setOrderType(String type) {
    _orderType = type;
    notifyListeners();
  }

  void add(MenuItem item, {List<CartTopping> toppings = const [], int qty = 1}) {
    // Try to find an existing line with the exact same item and toppings
    final index = _lines.indexWhere((l) => l.hasSameContent(item, toppings));
    if (index >= 0) {
      _lines[index].qty += qty;
    } else {
      _lines.add(CartLine(item: item, qty: qty, toppings: List.from(toppings)));
    }
    notifyListeners();
  }

  void addByLineId(String lineId) {
    final line = _lines.where((l) => l.id == lineId).firstOrNull;
    if (line != null) {
      line.qty++;
      notifyListeners();
    }
  }

  void decrementByLineId(String lineId) {
    final index = _lines.indexWhere((l) => l.id == lineId);
    if (index < 0) return;
    
    if (_lines[index].qty > 1) {
      _lines[index].qty--;
    } else {
      _lines.removeAt(index);
    }
    notifyListeners();
  }

  void removeByLineId(String lineId) {
    _lines.removeWhere((l) => l.id == lineId);
    notifyListeners();
  }

  // Legacy support just in case, but prefers lineId going forward
  void decrement(String itemId) {
    final index = _lines.lastIndexWhere((l) => l.item.id == itemId);
    if (index < 0) return;
    if (_lines[index].qty > 1) {
      _lines[index].qty--;
    } else {
      _lines.removeAt(index);
    }
    notifyListeners();
  }

  void clear() {
    if (_lines.isEmpty && _customer == null && _voucher == null && _redeemPoints == 0 && _orderType == 'TAKEAWAY') return;
    _lines.clear();
    _customer = null;
    _voucher = null;
    _redeemPoints = 0;
    _orderType = 'TAKEAWAY';
    notifyListeners();
  }
}
