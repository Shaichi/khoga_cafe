import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/order_api.dart';
import '../auth/auth_controller.dart';
import '../format.dart';
import '../theme.dart';
import 'cancel_order_screen.dart';
import 'order_labels.dart';
import 'refund_order_dialog.dart';

/// Screen — "Chi Tiết Đơn Hàng" per Figma Node 161:309.
/// Renders exact layout & styles using real data from backend OrderApi.
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
      if (mounted) {
        setState(() => _error = e is ApiException ? e.message : 'Không tải được thông tin đơn hàng');
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy đơn hàng thành công')),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : 'Lỗi xử lý hủy đơn')),
        );
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xử lý hoàn tiền thành công')),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : 'Lỗi xử lý hoàn tiền')),
        );
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
        foregroundColor: const Color(0xFF2C1A11),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Chi Tiết Đơn Hàng',
          style: TextStyle(
            fontFamily: 'Segoe UI',
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C1A11),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF3D2314)))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, key: const Key('order-detail-error'), style: const TextStyle(color: kDanger)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _load,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3D2314)),
                          child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  )
                : order == null
                    ? const SizedBox.shrink()
                    : _buildBody(order),
      ),
    );
  }

  Widget _buildBody(OrderDetail o) {
    final userRole = context.watch<AuthController>().profile?.role;
    final isManager = userRole == 'STORE_MANAGER' || userRole == 'BIZ_ADMIN';
    final formattedTime = (o.createdAt != null && o.createdAt!.contains('T'))
        ? o.createdAt!.split('T').last.substring(0, 5)
        : '--:--';
    final orderNumDisplay = o.orderNumber.startsWith('#') ? o.orderNumber : '#${o.orderNumber}';
    final orderIdDisplay = 'ORD-${o.id.length >= 8 ? o.id.substring(0, 8).toUpperCase() : o.id.toUpperCase()}';

    return Column(
      children: [
        Expanded(
          child: ListView(
            key: const Key('order-detail'),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Top Info Card per Figma (fill: #FDFAF7, stroke: #EADDD3, radius: 16)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFAF7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEADDD3)),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Số đơn hàng:', orderNumDisplay, isBoldValue: true),
                    const SizedBox(height: 8),
                    _buildInfoRow('Mã định danh (ID):', orderIdDisplay, isBoldValue: true),
                    const SizedBox(height: 8),
                    _buildInfoRow('Hình thức / Giờ:', '${orderTypeLabel(o.orderType)} | $formattedTime', isBoldValue: true),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Trạng thái thanh toán:',
                      paymentStatusLabel(o.paymentStatus).toUpperCase(),
                      isBoldValue: true,
                      valueColor: o.paymentStatus == 'PAID' ? const Color(0xFF2E7D32) : const Color(0xFFC6585E),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: DashedDivider(color: Color(0xFFEADDD3)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Trạng thái đơn hàng:',
                          style: TextStyle(
                            fontFamily: 'Segoe UI',
                            fontSize: 13,
                            color: Color(0xFF5C3826),
                          ),
                        ),
                        _buildStatusBadge(o.status),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section 1: Items List
              _buildSectionHeader('Danh sách món nước & bánh'),
              const SizedBox(height: 10),
              for (final item in o.items) _buildItemRow(item),

              const SizedBox(height: 24),

              // Section 2: Payment Details
              _buildSectionHeader('Chi tiết thanh toán'),
              const SizedBox(height: 10),
              _buildPaymentRow('Tổng tiền hàng:', '${formatVnd(o.subtotal)} đ'),
              const SizedBox(height: 8),
              _buildPaymentRow('Tổng chiết khấu:', '-${formatVnd(o.discount)} đ'),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: Color(0xFFF0E6DF), height: 1),
              ),
              _buildPaymentRow(
                'Khách đã trả (${paymentMethodLabel(o.paymentMethod)}):',
                '${formatVnd(o.total)} đ',
                isHighlight: true,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),

        // Bottom Action Buttons (Figma Node 161:309)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFF0EBE5))),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Button 1: HỦY ĐƠN & HOÀN TIỀN (Only if manager & not cancelled)
                if (isManager && o.status != 'CANCELLED') ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFCF6679),
                        side: const BorderSide(color: Color(0x33CF6679)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (o.paymentStatus == 'PAID') {
                          _refundOrder();
                        } else {
                          _cancelOrder();
                        }
                      },
                      child: const Text(
                        'HỦY ĐƠN & HOÀN TIỀN',
                        style: TextStyle(
                          fontFamily: 'Arial',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Button 2: IN LẠI HÓA ĐƠN
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D2314),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _printInvoice(o),
                    child: const Text(
                      'IN LẠI HÓA ĐƠN',
                      style: TextStyle(
                        fontFamily: 'Arial',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Button 3: QUAY LẠI
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3D2314),
                      side: const BorderSide(color: Color(0xFFEADDD3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'QUAY LẠI',
                      style: TextStyle(
                        fontFamily: 'Segoe UI',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBoldValue = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Segoe UI',
            fontSize: 13,
            color: Color(0xFF5C3826),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Segoe UI',
            fontSize: 13,
            fontWeight: isBoldValue ? FontWeight.bold : FontWeight.normal,
            color: valueColor ?? const Color(0xFF2C1A11),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case 'PENDING':
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
        text = 'Chờ pha chế';
        break;
      case 'PREPARING':
        bg = const Color(0xFFE3F2FD);
        fg = const Color(0xFF1565C0);
        text = 'Đang pha chế';
        break;
      case 'READY':
      case 'COMPLETED':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        text = 'Hoàn thành';
        break;
      case 'CANCELLED':
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC6585E);
        text = 'Đã hủy';
        break;
      default:
        bg = const Color(0xFFF5F5F5);
        fg = const Color(0xFF616161);
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Segoe UI',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Segoe UI',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8C766C),
          ),
        ),
        const SizedBox(height: 4),
        const Divider(color: Color(0xFFF0E6DF), height: 1, thickness: 1),
      ],
    );
  }

  Widget _buildItemRow(OrderItemLine line) {
    final toppingsText = line.toppings.isNotEmpty
        ? '- ${line.toppings.map((t) => t.name).join(', ')}'
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${line.quantity}x ${line.menuItemName}',
                  style: const TextStyle(
                    fontFamily: 'Segoe UI',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D2314),
                  ),
                ),
                if (toppingsText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    toppingsText,
                    style: const TextStyle(
                      fontFamily: 'Segoe UI',
                      fontSize: 11,
                      color: Color(0xFF8C766C),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${formatVnd(line.lineTotal)} đ',
            style: const TextStyle(
              fontFamily: 'Segoe UI',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C1A11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Segoe UI',
            fontSize: 13,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            color: isHighlight ? const Color(0xFF5C3826) : const Color(0xFF5C3826),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Segoe UI',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isHighlight ? const Color(0xFF3D2314) : const Color(0xFF2C1A11),
          ),
        ),
      ],
    );
  }

  void _printInvoice(OrderDetail order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hóa đơn thanh toán', textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('KHOGA CAFÉ', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text('Mã HĐ: ${order.orderNumber}', textAlign: TextAlign.center),
              Text('Thu ngân: ${context.read<AuthController>().profile?.fullName ?? ""}', textAlign: TextAlign.center),
              const Divider(height: 24),
              for (final item in order.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('${item.quantity}x ${item.menuItemName}')),
                      Text(formatVnd(item.unitPrice * item.quantity)),
                    ],
                  ),
                ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cộng tiền hàng (Tạm tính):'),
                  Text('${formatVnd(order.subtotal)} đ'),
                ],
              ),
              if (order.discount > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Giảm giá (Voucher/Hội viên):'),
                    Text('-${formatVnd(order.discount)} đ', style: const TextStyle(color: kDanger)),
                  ],
                ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TỔNG THANH TOÁN (NET):', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${formatVnd(order.total)} đ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Thuế VAT gồm trong giá (10%):', style: TextStyle(fontSize: 11, color: kMuted)),
                  Text('${formatVnd((order.total * 10 / 110).round())} đ', style: TextStyle(fontSize: 11, color: kMuted)),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Thanh toán bằng:'),
                  Text(paymentMethodLabel(order.paymentMethod), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Xin cảm ơn quý khách!\nHẹn gặp lại quý khách lần sau.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: kMuted, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
          ElevatedButton.icon(
            icon: const Icon(Icons.print),
            label: const Text('In'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang in hóa đơn...')));
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}

/// Helper DashedDivider widget for Figma design specification
class DashedDivider extends StatelessWidget {
  final Color color;
  final double height;
  final double dashWidth;
  final double dashSpace;

  const DashedDivider({
    super.key,
    this.color = const Color(0xFFEADDD3),
    this.height = 1.0,
    this.dashWidth = 4.0,
    this.dashSpace = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxWidth = constraints.constrainWidth();
          final count = (boxWidth / (dashWidth + dashSpace)).floor();
          return Flex(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            direction: Axis.horizontal,
            children: List.generate(count, (_) {
              return SizedBox(
                width: dashWidth,
                height: height,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: color),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
