import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/order_api.dart';
import '../format.dart';
import '../theme.dart';
import '../auth/auth_controller.dart';
import 'cancel_order_screen.dart';
import 'order_labels.dart';
import 'refund_order_dialog.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: kBrown,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Chi Tiết Đơn Hàng', style: TextStyle(fontWeight: FontWeight.bold, color: kBrown)),
        centerTitle: true,
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
    return Column(
      children: [
        Expanded(
          child: ListView(
            key: const Key('order-detail'),
            padding: const EdgeInsets.all(20),
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF0EBE5)),
                ),
                child: Column(
                  children: [
                    _infoRow('Số đơn hàng:', o.orderNumber, bold: true),
                    _infoRow('Mã định danh (ID):', o.id),
                    _infoRow('Hình thức / Giờ:', '${orderTypeLabel(o.orderType)} | ${o.createdAt?.split('T').last.substring(0, 5) ?? '--:--'}'),
                    _infoRow('Trạng thái thanh toán:', paymentStatusLabel(o.paymentStatus).toUpperCase(), color: kSuccess, bold: true),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: Color(0xFFE5E0DA), height: 1, thickness: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Trạng thái đơn hàng:', style: TextStyle(color: kMuted)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(o.status == 'PENDING' ? 'Chờ pha chế' : o.status == 'PREPARING' ? 'Đang pha chế' : 'Hoàn thành', 
                                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Items Section
              const Text('Danh sách món nước & bánh', style: TextStyle(fontWeight: FontWeight.bold, color: kMuted, fontSize: 13)),
              const Divider(color: Color(0xFFF0EBE5), thickness: 1),
              const SizedBox(height: 8),
              for (final line in o.items) _itemRow(line),
              
              const SizedBox(height: 16),
              
              // Payment Section
              const Text('Chi tiết thanh toán', style: TextStyle(fontWeight: FontWeight.bold, color: kMuted, fontSize: 13)),
              const Divider(color: Color(0xFFF0EBE5), thickness: 1),
              const SizedBox(height: 8),
              _totalRow('Tổng tiền hàng:', o.subtotal),
              if (o.discount > 0) _totalRow('Tổng chiết khấu:', -o.discount),
              const SizedBox(height: 8),
              _totalRow('Khách đã trả (${paymentMethodLabel(o.paymentMethod)}):', o.total, bold: true),
            ],
          ),
        ),
        
        // Bottom Actions
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFF0EBE5))),
          ),
          child: Column(
            children: [
              if (context.read<AuthController>().profile?.role != 'BARISTA') ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kDanger,
                      side: const BorderSide(color: Color(0xFFF8D7DA)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {},
                    child: const Text('HỦY ĐƠN & HOÀN TIỀN', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBrown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {},
                    child: const Text('IN LẠI HÓA ĐƠN', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kBrown,
                    side: const BorderSide(color: Color(0xFFF0EBE5)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('QUAY LẠI', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: kMuted)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: color ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
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
                Expanded(child: Text('${line.quantity}x ${line.menuItemName}', style: const TextStyle(fontWeight: FontWeight.bold))),
                Text('${formatVnd(line.lineTotal)} đ', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            if (line.toppings.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('- ${line.toppings.map((t) => t.name).join(', ')}', style: const TextStyle(color: kMuted, fontSize: 13)),
              ),
          ],
        ),
      );

  Widget _totalRow(String label, num value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: bold ? kBrown : kMuted, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
            Text('${formatVnd(value)} đ', style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.bold, color: bold ? kBrown : Colors.black87)),
          ],
        ),
      );
}
