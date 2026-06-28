import 'package:flutter/foundation.dart';

import '../api/models.dart';

/// One line in the cart: a menu item plus its quantity.
class CartLine {
  final MenuItem item;
  int qty;
  CartLine(this.item, this.qty);
  num get lineTotal => item.price * qty;
}

/// Local cart state for the POS (screen 35). Pure client-side until checkout (F5).
class CartController extends ChangeNotifier {
  final Map<String, CartLine> _lines = {};

  List<CartLine> get lines => _lines.values.toList(growable: false);
  bool get isEmpty => _lines.isEmpty;
  int get itemCount => _lines.values.fold(0, (sum, l) => sum + l.qty);
  num get subtotal => _lines.values.fold<num>(0, (sum, l) => sum + l.lineTotal);

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
    if (_lines.isEmpty) return;
    _lines.clear();
    notifyListeners();
  }
}
