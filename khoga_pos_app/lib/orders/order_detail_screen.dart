import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/order_api.dart';
import '../format.dart';
import '../theme.dart';
import 'order_labels.dart';

/// Screen 40/48 — full order detail (UC-73): header, line items with toppings,
/// and the payment summary. Reachable from the history list (49).
class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late final OrderApi _api;
  OrderDetail? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = OrderApi(context.read<ApiClient>());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final o = await _api.detail(widget.orderId);
      if (mounted) setState(() => _order = o);
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Không tải được đơn hàng');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrown,
        foregroundColor: Colors.white,
        title: const Text('Chi tiết đơn'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: Text('Đang tải…'))
            : _error != null
                ? Center(child: Text(_error!, key: const Key('order-detail-error'), style: const TextStyle(color: kDanger)))
                : order == null
                    ? const SizedBox.shrink()
                    : _body(order),
      ),
    );
  }

  Widget _body(OrderDetail o) {
    return ListView(
      key: const Key('order-detail'),
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(o.orderNumber, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kBrown)),
            StatusChip(o.status),
          ],
        ),
        const SizedBox(height: 4),
        Text('${orderTypeLabel(o.orderType)} · ${paymentMethodLabel(o.paymentMethod)} · ${paymentStatusLabel(o.paymentStatus)}',
            style: const TextStyle(color: kMuted, fontSize: 13)),
        if (o.customerName != null) ...[
          const SizedBox(height: 4),
          Text('Khách: ${o.customerName}', style: const TextStyle(color: kMuted, fontSize: 13)),
        ],
        const Divider(height: 28),
        const Text('Món', style: TextStyle(fontWeight: FontWeight.bold, color: kBrown)),
        const SizedBox(height: 8),
        for (final line in o.items) _itemRow(line),
        const Divider(height: 28),
        _totalRow('Tạm tính', o.subtotal),
        if (o.discount > 0) _totalRow('Giảm giá', -o.discount),
        _totalRow('Thuế', o.taxAmount),
        const SizedBox(height: 6),
        _totalRow('Tổng cộng', o.total, bold: true),
      ],
    );
  }

  Widget _itemRow(OrderItemLine line) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('${line.quantity}× ${line.menuItemName}')),
                Text('${formatVnd(line.lineTotal)} VND', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            for (final t in line.toppings)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 2),
                child: Text('+ ${t.quantity}× ${t.name}', style: const TextStyle(color: kMuted, fontSize: 12)),
              ),
          ],
        ),
      );

  Widget _totalRow(String label, num value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(color: bold ? kBrown : kMuted, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
            Text('${formatVnd(value)} VND',
                style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w600, color: bold ? kBrown : null)),
          ],
        ),
      );
}
