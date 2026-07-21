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
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: Color(0xFF2C1A11), size: 24),
                    ),
                  ),
                  const Text(
                    'Chi Tiết Đơn Hàng',
                    style: TextStyle(
                      fontFamily: 'Segoe UI',
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                      color: Color(0xFF2C1A11),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: _loading
                  ? const Center(child: Text('Đang tải…'))
                  : _error != null
                      ? Center(child: Text(_error!, key: const Key('order-detail-error'), style: const TextStyle(color: kDanger)))
                      : order == null
                          ? const SizedBox.shrink()
                          : _body(order),
            ),
            
            // Bottom Actions
            if (order != null && !_loading) _buildActionButtons(order),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(OrderDetail o) {
    final canCancel = o.status == 'PENDING';
    final canRefund = o.paymentStatus == 'PAID' && o.status != 'PENDING' && o.status != 'CANCELLED';
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canCancel || canRefund)
            Container(
              width: double.infinity,
              height: 48,
              margin: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color.fromRGBO(207, 102, 121, 0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: canCancel ? _cancelOrder : _refundOrder,
                child: Text(
                  canCancel ? 'HỦY ĐƠN' : 'HỦY ĐƠN & HOÀN TIỀN',
                  style: const TextStyle(
                    fontFamily: 'Arial',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFFCF6679),
                  ),
                ),
              ),
            ),
          Container(
            width: double.infinity,
            height: 48,
            margin: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D2314),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () {}, // Sắp có
              child: const Text(
                'IN LẠI HÓA ĐƠN',
                style: TextStyle(
                  fontFamily: 'Arial',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFEADDD3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'QUAY LẠI',
                style: TextStyle(
                  fontFamily: 'Segoe UI',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF3D2314),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(OrderDetail o) {
    return ListView(
      key: const Key('order-detail'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Info Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFAF7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEADDD3)),
          ),
          child: Column(
            children: [
              _infoRow('Số đơn hàng:', o.orderNumber, bold: true),
              _infoRow('Mã định danh (ID):', o.id),
              _infoRow('Hình thức / Giờ:', '${orderTypeLabel(o.orderType)} | ${o.createdAt?.split('T').last.substring(0, 5) ?? '--:--'}'),
              _infoRow('Trạng thái thanh toán:', paymentStatusLabel(o.paymentStatus).toUpperCase(), color: const Color(0xFF2E7D32), bold: true),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: Color(0xFFEADDD3), height: 1, thickness: 1), 
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Trạng thái đơn hàng:', style: TextStyle(fontFamily: 'Segoe UI', color: Color(0xFF5C3826), fontSize: 13)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      o.status == 'PENDING' ? 'Chờ pha chế' : o.status == 'PREPARING' ? 'Đang pha chế' : 'Hoàn thành',
                      style: const TextStyle(fontFamily: 'Segoe UI', color: Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Items Section
        Container(
          padding: const EdgeInsets.only(bottom: 4),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF0E6DF))),
          ),
          child: const Text(
            'Danh sách món nước & bánh',
            style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, color: Color(0xFF8C766C), fontSize: 12),
          ),
        ),
        const SizedBox(height: 8),
        for (final line in o.items) _itemRow(line),
        
        const SizedBox(height: 16),
        
        // Payment Section
        Container(
          padding: const EdgeInsets.only(bottom: 4),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF0E6DF))),
          ),
          child: const Text(
            'Chi tiết thanh toán',
            style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, color: Color(0xFF8C766C), fontSize: 12),
          ),
        ),
        const SizedBox(height: 8),
        _totalRow('Tổng tiền hàng:', o.subtotal),
        if (o.discount > 0) _totalRow('Tổng chiết khấu:', -o.discount),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.only(top: 8),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFF0E6DF))),
          ),
          child: _totalRow('Khách đã trả (${paymentMethodLabel(o.paymentMethod)}):', o.total, bold: true),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Segoe UI', color: Color(0xFF5C3826), fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Segoe UI',
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color ?? const Color(0xFF2C1A11),
              fontSize: 12.5,
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
                Expanded(
                  child: Text(
                    '${line.quantity}x ${line.menuItemName}',
                    style: const TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, color: Color(0xFF3D2314), fontSize: 13),
                  ),
                ),
                Text(
                  '${formatVnd(line.lineTotal)} đ',
                  style: const TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, color: Color(0xFF2C1A11), fontSize: 13),
                ),
              ],
            ),
            if (line.toppings.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '- ${line.toppings.map((t) => t.name).join(', ')}',
                  style: const TextStyle(fontFamily: 'Segoe UI', color: Color(0xFF8C766C), fontSize: 11),
                ),
              ),
          ],
        ),
      );

  Widget _totalRow(String label, num value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Segoe UI',
                color: const Color(0xFF5C3826),
                fontSize: 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text(
              '${formatVnd(value)} đ',
              style: TextStyle(
                fontFamily: 'Segoe UI',
                fontWeight: FontWeight.bold,
                color: bold ? const Color(0xFF3D2314) : const Color(0xFF2C1A11),
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      );
}
