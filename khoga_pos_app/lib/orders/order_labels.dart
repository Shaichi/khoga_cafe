import 'package:flutter/material.dart';

import '../theme.dart';

/// Vietnamese labels + colours for the order enums shared across the history and
/// detail screens.
String orderStatusLabel(String s) => switch (s) {
  'PENDING' => 'Chờ xử lý',
  'PREPARING' => 'Đang pha chế',
  'HOLD' => 'Tạm giữ',
  'READY' => 'Sẵn sàng',
  'COMPLETED' => 'Hoàn tất',
  'CANCELLED' => 'Đã hủy',
  'ABANDONED' => 'Bỏ dở',
  _ => s,
};

String paymentStatusLabel(String s) => switch (s) {
  'UNPAID' => 'Chưa thanh toán',
  'PAID' => 'Đã thanh toán',
  'REFUNDED' => 'Đã hoàn tiền',
  _ => s,
};

String paymentMethodLabel(String s) => switch (s) {
  'CASH' => 'Tiền mặt',
  'CARD' => 'Thẻ',
  'VIETQR' => 'VietQR',
  'LOYALTY_POINTS' => 'Điểm',
  _ => s,
};

String orderTypeLabel(String s) => switch (s) {
  'DINE_IN' => 'Tại quán',
  'TAKEAWAY' => 'Mang đi',
  'DELIVERY' => 'Giao hàng',
  _ => s,
};

/// The next lifecycle states a barista can advance an order to, with its action
/// label (UC-58), or empty when the order is terminal. Shared by the portrait
/// queue and the landscape barista portal.
List<(String, String)> baristaNextStatus(String status) => switch (status) {
  'PENDING' => [('PREPARING', 'Bắt đầu pha')],
  'HOLD' => [('PREPARING', 'Tiếp tục pha')],
  'PREPARING' => [('COMPLETED', 'Hoàn thành'), ('HOLD', 'Tạm giữ')],
  'READY' => [('COMPLETED', 'Giao khách')],
  _ => [],
};

Color orderStatusColor(String s) => switch (s) {
  'COMPLETED' => const Color(0xFF1E8A4C),
  'CANCELLED' || 'ABANDONED' => kDanger,
  'READY' => kGold,
  _ => kBrown,
};

/// Small coloured pill showing an order status.
class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = orderStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        orderStatusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
