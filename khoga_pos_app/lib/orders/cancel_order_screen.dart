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
                    // BR-07/BR-08 Warning notice
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'Lưu ý: Hệ thống chỉ hỗ trợ hủy đơn hàng ở trạng thái Chờ pha chế (PENDING). '
                        'Khi hủy thành công, các khuyến mãi (Voucher) đã áp dụng và điểm tích lũy '
                        'tiêu tốn sẽ tự động hoàn trả cho khách hàng.',
                        style: TextStyle(
                          color: Color(0xFFE65100),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Non-PENDING status error
                    if (!_canSubmit) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDECEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF3C9C6)),
                        ),
                        child: Text(
                          '❌ Không thể hủy: Đơn hàng này đang ở trạng thái '
                          '${_statusLabel(widget.status)}. Chỉ có thể hủy đơn hàng ở trạng thái Chờ pha chế.',
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
                                const TextSpan(text: 'Đơn hàng: ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                TextSpan(text: widget.orderNumber, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kBrown)),
                                const TextSpan(text: '  (Trạng thái: ', style: TextStyle(fontSize: 12)),
                                TextSpan(text: _statusLabel(widget.status), style: TextStyle(fontSize: 12, color: _statusColor(widget.status), fontWeight: FontWeight.w600)),
                                const TextSpan(text: ')', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Số tiền hoàn trả: ${formatVnd(widget.refundAmount)} VND',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Dropdown: Reason (mandatory)
                    const Text('Lý do hủy đơn *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kBrown)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      key: const Key('cancel-reason'),
                      value: _selectedReason,
                      hint: const Text('Chọn lý do...'),
                      items: _reasons
                          .map((r) => DropdownMenuItem(value: r.value, child: Text(r.label, style: const TextStyle(fontSize: 14))))
                          .toList(),
                      onChanged: _canSubmit ? (val) => setState(() => _selectedReason = val) : null,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),

                    // Textarea: Notes (mandatory)
                    const Text('Ghi chú chi tiết *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kBrown)),
                    const SizedBox(height: 6),
                    TextField(
                      key: const Key('cancel-notes'),
                      controller: _notesCtrl,
                      enabled: _canSubmit,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Giải trình lý do hủy đơn bắt buộc...',
                        border: OutlineInputBorder(),
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
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                        child: const Text('HỦY BỎ'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        key: const Key('confirm-cancel'),
                        onPressed: !_canSubmit || _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kDanger,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('XÁC NHẬN HỦY', style: TextStyle(color: Colors.white)),
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
