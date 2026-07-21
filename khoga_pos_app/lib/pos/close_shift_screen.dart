import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../format.dart';
import '../theme.dart';
import 'shift_controller.dart';

/// Screen 41 — "Close Shift / Z-report". The cashier counts the drawer, submits
/// the closing cash, and the backend returns the reconciliation (UC-53, BR-34).
/// On success the active shift is cleared, so dismissing this screen falls back
/// to the open-shift gate.
class CloseShiftScreen extends StatefulWidget {
  const CloseShiftScreen({super.key});

  @override
  State<CloseShiftScreen> createState() => _CloseShiftScreenState();
}

class _CloseShiftScreenState extends State<CloseShiftScreen> {
  final _cash = TextEditingController();
  final _notes = TextEditingController();
  bool _submitting = false;
  String? _error;
  ZReport? _report;
  
  ZReport? _preview;
  bool _loadingPreview = true;
  bool _ordersConfirmed = false;

  @override
  void initState() {
    super.initState();
    _cash.addListener(_onCashChanged);
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    try {
      final p = await context.read<ShiftController>().previewClose();
      if (mounted) setState(() { _preview = p; _loadingPreview = false; });
    } catch (e) {
      if (mounted) setState(() { _loadingPreview = false; _error = 'Không thể tải tiền dự kiến'; });
    }
  }

  @override
  void dispose() {
    _cash.removeListener(_onCashChanged);
    _cash.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _onCashChanged() => setState(() {});

  /// Returns null if no discrepancy, otherwise the absolute difference.
  num? get _discrepancy {
    if (_preview == null) return null;
    final actual = num.tryParse(_cash.text.trim());
    if (actual == null) return null;
    final diff = (actual - _preview!.expectedCash).abs();
    return diff > 0.001 ? diff : null;
  }

  bool get _isSevereDiscrepancy => (_discrepancy ?? 0) > 100000;
  bool get _hasDiscrepancy => _discrepancy != null;

  Future<void> _submit() async {
    final cash = num.tryParse(_cash.text.trim());
    if (_cash.text.trim().isEmpty || cash == null || cash < 0) {
      setState(() => _error = 'Vui lòng nhập số tiền mặt kiểm đếm');
      return;
    }
    // Require notes when discrepancy exists
    if (_hasDiscrepancy && _notes.text.trim().isEmpty) {
      setState(() => _error = 'Giải trình lý do chênh lệch két tiền bàn giao là bắt buộc');
      return;
    }
    if (!_ordersConfirmed) {
      setState(() => _error = 'Vui lòng xác nhận đã xử lý xong toàn bộ đơn hàng trong ca trước khi đóng.');
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      final notes = _notes.text.trim();
      final report = await context.read<ShiftController>().close(cash, notes: notes.isNotEmpty ? notes : null);
      if (mounted) setState(() => _report = report);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Không kết nối được máy chủ');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrown,
        foregroundColor: Colors.white,
        title: const Text('Kết ca'),
        automaticallyImplyLeading: report == null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: report == null ? _form(context) : _zReport(context, report),
          ),
        ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    final register = context.read<ShiftController>().active?.posRegisterId ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Đóng ca máy $register',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBrown)),
        const SizedBox(height: 4),
        const Text('Đếm tiền mặt thực tế trong ngăn kéo trước khi kết ca.',
            style: TextStyle(color: kMuted, fontSize: 13)),
        const SizedBox(height: 24),
        if (_error != null) ...[
          _errorBox(_error!),
          const SizedBox(height: 16),
        ],
        // Real-time discrepancy warning
        if (_hasDiscrepancy) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isSevereDiscrepancy ? const Color(0xFFFFE8E8) : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isSevereDiscrepancy ? const Color(0xFFCF6679).withValues(alpha: 0.2) : const Color(0xFFFFB300).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              _isSevereDiscrepancy
                  ? '⚠️ Lưu ý quan trọng: Sai lệch tiền trong két thực tế vượt quá 100,000 VND '
                    '(Cụ thể lệch: ${formatVnd(_discrepancy!)} VND). Báo cáo sự cố sẽ được gửi trực tiếp đến Quản lý cửa hàng.'
                  : '⚠️ Có chênh lệch két tiền thực tế so với sổ sách (${formatVnd(_discrepancy!)} VND). '
                    'Bạn bắt buộc phải ghi rõ lý do giải trình.',
              style: TextStyle(
                color: _isSevereDiscrepancy ? kDanger : const Color(0xFFB78103),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_loadingPreview) 
           const Center(child: CircularProgressIndicator())
        else if (_preview != null) ...[
           const Text('Doanh thu tiền mặt hệ thống (Expected)', style: TextStyle(color: kMuted)),
           const SizedBox(height: 4),
           Text('${formatVnd(_preview!.expectedCash)} VND', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBrown)),
           const SizedBox(height: 24),
        ],
        const Text('Tiền mặt kiểm đếm thực tế *',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBrown)),
        const SizedBox(height: 8),
        TextField(
          key: const Key('closing-cash'),
          controller: _cash,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(hintText: 'Nhập số tiền mặt trong két...', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        Text(_hasDiscrepancy ? 'Ghi chú sai lệch (Bắt buộc) *' : 'Ghi chú sai lệch (Nếu có)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _hasDiscrepancy ? kDanger : kBrown)),
        const SizedBox(height: 8),
        TextField(
          key: const Key('discrepancy-notes'),
          controller: _notes,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Giải trình lý do chênh lệch két tiền nếu có...', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        // BR-03 checkbox
        CheckboxListTile(
          key: const Key('orders-confirmed'),
          value: _ordersConfirmed,
          onChanged: (v) => setState(() => _ordersConfirmed = v ?? false),
          activeColor: kBrown,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text(
            'Tôi xác nhận tất cả đơn hàng trong ca đã được xử lý xong (Hoàn thành hoặc Hủy)',
            style: TextStyle(fontSize: 12, color: kBrown, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 20),
          ElevatedButton(
            key: const Key('close-shift-button'),
            onPressed: _submitting ? null : () async {
              final cash = num.tryParse(_cash.text.replaceAll(RegExp(r'[^0-9]'), ''));
              if (cash == null) {
                setState(() => _error = 'Vui lòng nhập tiền kiểm đếm');
                return;
              }
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Xác nhận kết ca'),
                  content: const Text('Bạn có chắc chắn muốn đóng ca làm việc này?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('HỦY')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: kDanger),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('XÁC NHẬN ĐÓNG CA'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) _submit();
            },
            child: _submitting
                ? const SizedBox(
                    height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('ĐỒNG Ý ĐÓNG CA'),
          ),
      ],
    );
  }

  Widget _zReport(BuildContext context, ZReport z) {
    final flagged = z.discrepancyFlagged;
    return Column(
      key: const Key('z-report'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.receipt_long, size: 48, color: kBrown),
        const SizedBox(height: 8),
        Text('Báo cáo kết ca · ${z.posRegisterId}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBrown)),
        const SizedBox(height: 20),
        _row('Tiền đầu ca', z.openingCash),
        const Divider(height: 16),
        _textRow('Tổng số đơn', '${z.totalOrders} đơn'),
        if (z.cancelledOrders > 0) _textRow('Đơn hủy', '${z.cancelledOrders} đơn', color: kDanger),
        const SizedBox(height: 8),
        _row('Doanh thu tiền mặt', z.totalCashSales),
        _row('Doanh thu thẻ (POS)', z.totalCardSales),
        _row('Doanh thu VietQR', z.totalVietQrSales),
        const Divider(height: 16),
        _row('Tiền dự kiến (chỉ tính TM)', z.expectedCash),
        _row('Tiền kiểm đếm', z.closingCash),
        const Divider(height: 28),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: flagged ? const Color(0xFFFDECEB) : const Color(0xFFE9F7EF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: flagged ? const Color(0xFFF3C9C6) : const Color(0xFFB7E1C7)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                flagged ? 'Lệch quỹ' : 'Khớp tiền',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: flagged ? kDanger : const Color(0xFF1E8A4C)),
              ),
              Text(
                '${z.discrepancy > 0 ? '+' : ''}${formatVnd(z.discrepancy)} VND',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: flagged ? kDanger : const Color(0xFF1E8A4C)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
          ElevatedButton(
            key: const Key('z-report-done'),
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('HOÀN TẤT'),
          ),
      ],
    );
  }

    Widget _row(String label, num value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: kMuted, fontSize: 14))),
            Text('${formatVnd(value)} VND', style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _textRow(String label, String value, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: kMuted, fontSize: 14))),
            Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      );

  Widget _errorBox(String message) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFDECEB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFF3C9C6)),
        ),
        child: Text(message, style: const TextStyle(color: kDanger, fontSize: 14)),
      );
}
