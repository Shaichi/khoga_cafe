import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/order_api.dart';
import '../format.dart';
import '../theme.dart';
import '../orders/order_labels.dart';

class ManagerOrderDetailScreen extends StatefulWidget {
  final String orderId;
  const ManagerOrderDetailScreen({super.key, required this.orderId});

  @override
  State<ManagerOrderDetailScreen> createState() => _ManagerOrderDetailScreenState();
}

class _ManagerOrderDetailScreenState extends State<ManagerOrderDetailScreen> {
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
      if (mounted) {
        setState(() => _error = e is ApiException ? e.message : 'Không tải được đơn hàng');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: kBrownDark,
        elevation: 0,
        title: const Text(
          'Chi Tiết Đơn Hàng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: kBrownDark))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: const TextStyle(color: kDanger)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _load,
                          style: ElevatedButton.styleFrom(backgroundColor: kBrownDark),
                          child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  )
                : _order == null
                    ? const SizedBox.shrink()
                    : _buildContent(_order!),
      ),
    );
  }

  Widget _buildContent(OrderDetail o) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      o.orderNumber,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kBrownDark,
                      ),
                    ),
                    StatusChip(o.status),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Loại đơn', orderTypeLabel(o.orderType)),
                _buildInfoRow('Khách hàng', o.customerName ?? 'Khách vãng lai'),
                _buildInfoRow('Thanh toán', paymentMethodLabel(o.paymentMethod)),
                _buildInfoRow('Trạng thái TT', paymentStatusLabel(o.paymentStatus)),
                if (o.createdAt != null) ...[
                  _buildInfoRow('Thời gian tạo', o.createdAt!),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),

          // Items Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chi tiết món',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kBrownDark,
                  ),
                ),
                const SizedBox(height: 12),
                for (int i = 0; i < o.items.length; i++) ...[
                  _buildItemRow(o.items[i]),
                  if (i < o.items.length - 1)
                    const Divider(height: 24, color: kBorder),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tổng kết thanh toán',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kBrownDark,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTotalRow('Tạm tính', o.subtotal),
                if (o.discount > 0) _buildTotalRow('Giảm giá', -o.discount),
                if (o.taxAmount > 0) _buildTotalRow('Thuế (VAT)', o.taxAmount),
                const Divider(height: 24, color: kBorder),
                _buildTotalRow('Tổng cộng', o.total, isTotal: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: kMuted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: kBrownDark)),
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderItemLine line) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${line.quantity}x ${line.menuItemName}',
                style: const TextStyle(fontWeight: FontWeight.w600, color: kBrownDark),
              ),
            ),
            Text(
              '${formatVnd(line.lineTotal)}đ',
              style: const TextStyle(fontWeight: FontWeight.w600, color: kBrownDark),
            ),
          ],
        ),
        if (line.toppings.isNotEmpty) ...[
          const SizedBox(height: 4),
          for (final t in line.toppings)
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 2),
              child: Text(
                '+ ${t.quantity}x ${t.name}',
                style: const TextStyle(color: kMuted, fontSize: 13),
              ),
            ),
        ]
      ],
    );
  }

  Widget _buildTotalRow(String label, num value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? kBrownDark : kMuted,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            '${formatVnd(value)}đ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isTotal ? kBrown : kBrownDark,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
