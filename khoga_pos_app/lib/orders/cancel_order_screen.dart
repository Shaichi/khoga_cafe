import 'package:flutter/material.dart';

import '../theme.dart';
import '../format.dart';

/// Screen matching mockup `cancel_override.html` — full page cancel flow with:
/// 1. BR-07/BR-08 warning notice
/// 2. Read-only order info (number + refund amount)
/// 3. Dropdown reason selection (mandatory)
/// 4. Separate textarea notes (mandatory)
///
/// Returns a `Map<String, String>` with keys `reason` and `notes` on success,
/// or `null` if cancelled.
class CancelOrderScreen extends StatefulWidget {
  final String orderNumber;
  final num refundAmount;
  final String status;

  const CancelOrderScreen({
    super.key,
    required this.orderNumber,
    required this.refundAmount,
    required this.status,
  });

  @override
  State<CancelOrderScreen> createState() => _CancelOrderScreenState();
}

class _CancelOrderScreenState extends State<CancelOrderScreen> {
  static const _reasons = [
    (value: 'customer_request', label: 'Khách hàng đổi ý / yêu cầu đổi trả món'),
    (value: 'wrong_entry', label: 'Thu ngân nhập sai thông tin đơn'),
    (value: 'other', label: 'Lý do khác'),
  ];

  String? _selectedReason;
  final _notesCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit => widget.status == 'PENDING';

  void _submit() {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn lý do hủy đơn')),
      );
      return;
    }
    final notes = _notesCtrl.text.trim();
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập ghi chú chi tiết')),
      );
      return;
    }
    Navigator.of(context).pop({
      'reason': _selectedReason!,
      'notes': notes,
    });
  }

  String _statusLabel(String s) => switch (s) {
        'PENDING' => 'Chờ pha chế',
        'PREPARING' => 'Đang pha chế',
        'READY' => 'Chờ lấy hàng',
        'COMPLETED' => 'Đã hoàn thành',
        'CANCELLED' => 'Đã hủy',
        _ => s,
      };

  Color _statusColor(String s) => switch (s) {
        'PENDING' => const Color(0xFFE67E22),
        _ => kDanger,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrown,
        foregroundColor: Colors.white,
        title: const Text('Hủy Đơn Hàng'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // BR-07/BR-08 Warning notice (Figma design handles PREPARING state)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        widget.status == 'PREPARING'
                            ? 'Cảnh báo: Đơn hàng này đang ở trạng thái pha chế. Nếu xác nhận hủy, nguyên liệu đã sử dụng sẽ tính là hao hụt và KHÔNG hoàn lại kho.'
                            : 'Lưu ý: Hệ thống chỉ hỗ trợ hủy đơn hàng ở trạng thái Chờ pha chế (PENDING). Khi hủy thành công, các khuyến mãi (Voucher) đã áp dụng và điểm tích lũy tiêu tốn sẽ tự động hoàn trả cho khách hàng.',
                        style: const TextStyle(
                          color: Color(0xFFE65100),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Non-PENDING status error
                    if (!_canSubmit && widget.status != 'PREPARING') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDECEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF3C9C6)),
                        ),
                        child: Text(
                          '❌ Không thể hủy: Đơn hàng này đang ở trạng thái '
                          '${_statusLabel(widget.status)}.',
                          style: const TextStyle(color: kDanger, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Read-only order info
                    const Text('Thông tin đơn hủy',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kBrown)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF8F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEADDD3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: 'Đơn hàng: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF3D2314))),
                                TextSpan(text: widget.orderNumber, style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12, color: Color(0xFF3D2314))),
                                const TextSpan(text: ' (Trạng thái: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Color(0xFF3D2314))),
                                TextSpan(text: _statusLabel(widget.status), style: const TextStyle(fontSize: 12, color: Color(0xFF3D2314), fontWeight: FontWeight.normal)),
                                const TextSpan(text: ')', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Color(0xFF3D2314))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: 'Số tiền hoàn trả: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF3D2314))),
                                TextSpan(text: '${formatVnd(widget.refundAmount)} VND', style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12, color: Color(0xFF3D2314))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Dropdown: Reason (mandatory)
                    const Text('Lý do hủy đơn *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF5C3826))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      key: const Key('cancel-reason'),
                      value: _selectedReason,
                      hint: const Text('Chọn lý do...', style: TextStyle(fontSize: 14, color: Color(0xFF2C1A11))),
                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF5C3826)),
                      items: _reasons
                          .map((r) => DropdownMenuItem(value: r.value, child: Text(r.label, style: const TextStyle(fontSize: 14, color: Color(0xFF2C1A11)))))
                          .toList(),
                      onChanged: (_canSubmit || widget.status == 'PREPARING') ? (val) => setState(() => _selectedReason = val) : null,
                      decoration: InputDecoration(
                        fillColor: const Color(0xFFFAFAFA),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEADDD3))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kGold, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Textarea: Notes (mandatory)
                    const Text('Ghi chú chi tiết *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF5C3826))),
                    const SizedBox(height: 6),
                    TextField(
                      key: const Key('cancel-notes'),
                      controller: _notesCtrl,
                      enabled: _canSubmit || widget.status == 'PREPARING',
                      maxLines: 3,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF2C1A11)),
                      decoration: InputDecoration(
                        hintText: 'Giải trình lý do hủy đơn bắt buộc...',
                        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF2C1A11)),
                        fillColor: const Color(0xFFFAFAFA),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEADDD3))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kGold, width: 2)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: kBorder)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          side: const BorderSide(color: Color(0xFFEADDD3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('HỦY BỎ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF3D2314))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        key: const Key('confirm-cancel'),
                        onPressed: (!(_canSubmit || widget.status == 'PREPARING') || _submitting) ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCF6679),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('XÁC NHẬN HỦY', style: TextStyle(color: Colors.white, fontSize: 13.9, fontWeight: FontWeight.bold, fontFamily: 'Arial')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
