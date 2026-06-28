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
  bool _submitting = false;
  String? _error;
  ZReport? _report;

  @override
  void dispose() {
    _cash.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cash = num.tryParse(_cash.text.trim());
    if (_cash.text.trim().isEmpty || cash == null || cash < 0) {
      setState(() => _error = 'Vui lòng nhập số tiền mặt kiểm đếm');
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      final report = await context.read<ShiftController>().close(cash);
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
        const Text('Tiền mặt kiểm đếm (VND) *',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBrown)),
        const SizedBox(height: 8),
        TextField(
          key: const Key('closing-cash'),
          controller: _cash,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(hintText: 'vd: 1200000'),
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          key: const Key('close-shift-button'),
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('ĐÓNG CA'),
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
        _row('Doanh thu tiền mặt', z.totalCashSales),
        _row('Tiền dự kiến', z.expectedCash),
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
          onPressed: () => Navigator.of(context).maybePop(),
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
            Text(label, style: const TextStyle(color: kMuted, fontSize: 14)),
            Text('${formatVnd(value)} VND', style: const TextStyle(fontWeight: FontWeight.w600)),
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
