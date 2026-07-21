import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/models.dart';
import '../auth/auth_controller.dart';
import '../format.dart';
import '../theme.dart';

class InvoiceDialog extends StatefulWidget {
  final OrderDetail order;
  const InvoiceDialog({super.key, required this.order});

  @override
  State<InvoiceDialog> createState() => _InvoiceDialogState();
}

class _InvoiceDialogState extends State<InvoiceDialog> {
  bool _isPrinting = true;

  @override
  void initState() {
    super.initState();
    // Simulate printing delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isPrinting = false);
    });
  }

  String _methodLabel(String method) => switch (method) {
        'CASH' => 'TIỀN MẶT',
        'BANK_TRANSFER' => 'CHUYỂN KHOẢN',
        _ => method,
      };

  @override
  Widget build(BuildContext context) {
    final profile = context.read<AuthController>().profile;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Hóa Đơn Bán Hàng',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Segoe UI',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF2C1A11),
              ),
            ),
            const SizedBox(height: 16),
            if (_isPrinting) ...[
              const Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    color: Color(0xFF3D2314),
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Đang in hóa đơn...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Segoe UI',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF8C766C),
                ),
              ),
            ] else ...[
              const SizedBox(height: 40), // Placeholder for spacing when not printing
            ],
            const SizedBox(height: 16),
            
            // Receipt Preview
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEADDD3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      color: Color(0xFF333333),
                      fontSize: 11,
                      height: 1.4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'KHOGA CAFÉ',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                        ),
                        Text(
                          'Chi nhánh: ${profile?.storeName ?? "Khoga Flagship"}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF666666)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: Text('Số HD: #${widget.order.id.split('-').last.toUpperCase()}')),
                            const SizedBox(width: 8),
                            Text('Mã: ${widget.order.orderNumber}'),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: Text('Ngày: ${formatDateTime(widget.order.createdAt)}')),
                            const SizedBox(width: 8),
                            Text('Thu ngân: ${profile?.username ?? ""}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const _DashedDivider(),
                        const SizedBox(height: 8),
                        const Text('CHI TIẾT ĐƠN HÀNG:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        const SizedBox(height: 4),
                        for (final item in widget.order.items) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: Text('${item.quantity}x ${item.menuItemName}')),
                              Text('${formatVnd(item.unitPrice * item.quantity)} đ'),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        const _DashedDivider(),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(child: Text('Cộng tiền hàng (Tạm tính):')),
                            Text('${formatVnd(widget.order.subtotal)} đ'),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(child: Text('Giảm giá (Hội viên/Voucher):')),
                            Text('-${formatVnd(widget.order.discount)} đ'),
                          ],
                        ),
                        // Đổi điểm tích lũy is currently not in OrderModel, hardcode or ignore
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: Text('Đổi điểm tích lũy:')),
                            Text('-0 đ'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const _DashedDivider(),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(child: Text('TỔNG THANH TOÁN (NET):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black))),
                            Text('${formatVnd(widget.order.total)} đ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black)),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(child: Text('Thuế VAT gồm trong giá (10%):', style: TextStyle(fontSize: 10, color: Color(0xFF666666)))),
                            Text('${formatVnd((widget.order.total * 10 / 110).round())} đ', style: const TextStyle(fontSize: 10, color: Color(0xFF666666))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const _DashedDivider(),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(child: Text('Thanh toán bằng:')),
                            Text(_methodLabel(widget.order.paymentMethod), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Xin cảm ơn quý khách!\nHẹn gặp lại quý khách lần sau.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10, color: Color(0xFF666666)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Bottom Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isPrinting ? null : () {
                      setState(() => _isPrinting = true);
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) setState(() => _isPrinting = false);
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3D2314),
                      side: const BorderSide(color: Color(0xFFEADDD3), width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'IN LẠI (REPRINT)',
                      style: TextStyle(fontFamily: 'Arial', fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D2314),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'HOÀN THÀNH (DONE)',
                      style: TextStyle(fontFamily: 'Arial', fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFBBBBBB)),
              ),
            );
          }),
        );
      },
    );
  }
}

