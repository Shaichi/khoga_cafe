import 'api_client.dart';
import 'models.dart';
import '../pos/cart_controller.dart';

/// A checkout payload mirroring com.khoga.pos.dto.CheckoutRequest. Built from the
/// cart plus the chosen payment method (and optional member/voucher/points).
class CheckoutRequestData {
  final List<CartLine> lines;
  final String paymentMethod; // CASH / CARD / VIETQR / LOYALTY_POINTS
  final num? cashReceived;
  final String? customerId;
  final String? voucherCode;
  final int redeemPoints;

  CheckoutRequestData({
    required this.lines,
    required this.paymentMethod,
    this.cashReceived,
    this.customerId,
    this.voucherCode,
    this.redeemPoints = 0,
  });

  Map<String, dynamic> toJson() => {
        if (customerId != null) 'customerId': customerId,
        if (voucherCode != null && voucherCode!.isNotEmpty) 'voucherCode': voucherCode,
        'redeemPoints': redeemPoints,
        'paymentMethod': paymentMethod,
        if (cashReceived != null) 'cashReceived': cashReceived,
        'items': [
          for (final l in lines) {'menuItemId': l.item.id, 'quantity': l.qty},
        ],
      };
}

/// Checkout endpoints (UC-48/49/51).
class CheckoutApi {
  final ApiClient _client;
  CheckoutApi(this._client);

  /// Preview the discount/tax breakdown without creating an order.
  Future<CheckoutBreakdown> preview(CheckoutRequestData req) async {
    final data = await _client.post('/checkout/preview', req.toJson());
    return CheckoutBreakdown.fromJson(data as Map<String, dynamic>);
  }

  /// Submit the order and take payment.
  Future<CheckoutResult> submit(CheckoutRequestData req) async {
    final data = await _client.post('/checkout', req.toJson());
    return CheckoutResult.fromJson(data as Map<String, dynamic>);
  }
}
