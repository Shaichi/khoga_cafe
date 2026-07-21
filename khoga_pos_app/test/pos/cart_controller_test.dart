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

    test('clear empties the cart and resets member/voucher/points', () {
      final cart = CartController()..add(_item('m1', 30000));
      cart.attachCustomer(CustomerLite(id: 'c1', fullName: 'A', points: 500));
      cart.applyVoucher(VoucherLite(id: 'v1', code: 'GIAM10', discountType: 'FIXED', discountValue: 10000));
      cart.setRedeemPoints(200);
      cart.clear();
      expect(cart.isEmpty, isTrue);
      expect(cart.subtotal, 0);
      expect(cart.customer, isNull);
      expect(cart.voucherCode, isNull);
      expect(cart.redeemPoints, 0);
    });

    test('applyVoucher sets voucher; clearVoucher removes it', () {
      final cart = CartController();
      cart.applyVoucher(VoucherLite(id: 'v1', code: 'GIAM10', discountType: 'FIXED', discountValue: 10000));
      expect(cart.voucherCode, 'GIAM10');
      cart.clearVoucher();
      expect(cart.voucherCode, isNull);
    });

    test('redeemPoints is clamped to the member balance and needs a member', () {
      final cart = CartController();
      cart.setRedeemPoints(300);
      expect(cart.redeemPoints, 0); // no member → nothing to redeem
      cart.attachCustomer(CustomerLite(id: 'c1', fullName: 'A', points: 250));
      cart.setRedeemPoints(300);
      expect(cart.redeemPoints, 250); // clamped to balance
      cart.clearCustomer();
      expect(cart.redeemPoints, 0); // removing the member drops redemption
    });
  });
}
