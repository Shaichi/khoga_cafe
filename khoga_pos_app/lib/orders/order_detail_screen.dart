import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/order_api.dart';
import '../format.dart';
import '../theme.dart';
import 'cancel_order_screen.dart';
import 'order_labels.dart';
import 'refund_order_dialog.dart';

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

  Future<void> _cancelOrder() async {
    final order = _order;
    if (order == null) return;

    final result = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(
        builder: (_) => CancelOrderScreen(
          orderNumber: order.orderNumber,
          refundAmount: order.total,
          status: order.status,
        ),
      ),
    );
    if (result == null) return;

    setState(() => _loading = true);
    try {
      await _api.cancel(widget.orderId, result['reason']!, notes: result['notes']);
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy đơn thành công')));
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'Lỗi hủy đơn')));
      }
    }
  }

  Future<void> _refundOrder() async {
    final order = _order;
    if (order == null) return;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => RefundOrderDialog(amount: order.total),
    );
    if (result == null) return;
    
    setState(() => _loading = true);
    try {
      await _api.refund(widget.orderId, result['type'], result['reason'], result['smPin']);
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hoàn tiền / làm lại thành công')));
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'Lỗi xử lý')));
      }
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
      bottomNavigationBar: (order != null && !_loading) ? _buildActionButtons(order) : null,
    );
  }

  Widget _buildActionButtons(OrderDetail o) {
    final canCancel = o.status == 'PENDING';
    final canRefund = o.paymentStatus == 'PAID' && o.status != 'PENDING' && o.status != 'CANCELLED';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: kBorder)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('In HĐ (Sắp có)'),
                onPressed: null,
              ),
            ),
            if (canCancel) ...[
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text('Hủy Đơn'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: _cancelOrder,
                ),
              ),
            ],
            if (canRefund) ...[
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.undo),
                  label: const Text('Hoàn Tiền'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: _refundOrder,
                ),
              ),
            ],
          ],
        ),
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
