import 'package:flutter/material.dart';

import '../orders/order_detail_screen.dart';

/// Wrapper screen — Chi Tiết Đơn Hàng cho Quản lý (Manager).
/// Renders [OrderDetailScreen] per Figma Node 161:309.
class ManagerOrderDetailScreen extends StatelessWidget {
  final String orderId;
  const ManagerOrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return OrderDetailScreen(orderId: orderId);
  }
}
