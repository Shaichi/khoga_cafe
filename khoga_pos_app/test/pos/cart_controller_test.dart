import 'package:flutter_test/flutter_test.dart';
import 'package:khoga_pos_app/api/models.dart';
import 'package:khoga_pos_app/pos/cart_controller.dart';

MenuItem _item(String id, num price) => MenuItem(id: id, name: 'Item $id', price: price);

void main() {
  group('CartController', () {
    test('adding the same item accumulates quantity and subtotal', () {
      final cart = CartController();
      final esp = _item('m1', 30000);
      cart.add(esp);
      cart.add(esp);
      expect(cart.lines.length, 1);
      expect(cart.itemCount, 2);
      expect(cart.subtotal, 60000);
    });

    test('subtotal sums distinct items', () {
      final cart = CartController();
      cart.add(_item('m1', 30000));
      cart.add(_item('m2', 25000));
      expect(cart.subtotal, 55000);
    });

    test('decrement removes the line when it hits zero', () {
      final cart = CartController();
      cart.add(_item('m1', 30000));
      cart.decrement('m1');
      expect(cart.isEmpty, isTrue);
    });

    test('clear empties the cart', () {
      final cart = CartController()..add(_item('m1', 30000));
      cart.clear();
      expect(cart.isEmpty, isTrue);
      expect(cart.subtotal, 0);
    });
  });
}
