import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/checkout_api.dart';
import '../api/models.dart';
import '../format.dart';
import '../theme.dart';
import 'cart_controller.dart';

/// Screen 38 — "Payment Checkout Modal". Previews the breakdown, lets the cashier
/// pick a method (cash/card/VietQR) and, for cash, the amount tendered, then
/// submits the order. CASH is the fully-wired path; VietQR shows the returned
/// code + an awaiting-payment state (the gateway callback flow is deferred).
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const _methods = [
    ('CASH', 'Tiền mặt', Icons.payments_outlined),
    ('CARD', 'Thẻ (POS)', Icons.credit_card),
    ('VIETQR', 'Chuyển VietQR', Icons.qr_code_2),
  ];

  late final CheckoutApi _api;
  late final CartController _cart;
  final _cashCtrl = TextEditingController();

  String _method = 'CASH';
  CheckoutBreakdown? _breakdown;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  CheckoutResult? _result;

  @override
  void initState() {
    super.initState();
    _api = CheckoutApi(context.read<ApiClient>());
    _cart = context.read<CartController>();
    _loadPreview();
  }

  @override
  void dispose() {
    _cashCtrl.dispose();
    super.dispose();
  }

  CheckoutRequestData _request({num? cashReceived}) =>
      CheckoutRequestData(lines: _cart.lines, paymentMethod: _method, cashReceived: cashReceived);

  Future<void> _loadPreview() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final b = await _api.preview(_request());
      if (mounted) setState(() => _breakdown = b);
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Không tải được hóa đơn');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  num get _net => _breakdown?.netTotalPayable ?? 0;
  num get _cashReceived => num.tryParse(_cashCtrl.text.trim()) ?? 0;
  num get _change => (_cashReceived - _net).clamp(0, double.infinity);

  Future<void> _confirm() async {
    if (_method == 'CASH' && _cashReceived < _net) {
      setState(() => _error = 'Tiền khách đưa chưa đủ');
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      final res = await _api.submit(_request(cashReceived: _method == 'CASH' ? _cashReceived : null));
      _cart.clear();
      if (mounted) setState(() => _result = res);
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Thanh toán thất bại');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: kBrown,
        elevation: 0,
        title: const Text('Thanh Toán', style: TextStyle(color: kBrown, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _result != null
            ? _success(_result!)
            : _loading
                ? const Center(child: Text('Đang tải hóa đơn…'))
                : _form(),
      ),
    );
  }

  Widget _form() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kBgAlt, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                const Text('Tổng tiền cần thanh toán', style: TextStyle(color: kMuted)),
                const SizedBox(height: 4),
                Text('${formatVnd(_net)} VND',
                    key: const Key('payable-total'),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kBrown)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Phương thức thanh toán', style: TextStyle(fontWeight: FontWeight.w600, color: kBrown)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final m in _methods) _methodTile(m.$1, m.$2, m.$3),
            ],
          ),
          if (_method == 'CASH') ...[
            const SizedBox(height: 20),
            const Text('Tiền mặt khách đưa (VND) *',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBrown)),
            const SizedBox(height: 8),
            TextField(
              key: const Key('cash-received'),
              controller: _cashCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                for (final q in [50000, 100000, 200000, 500000])
                  OutlinedButton(
                    onPressed: () => setState(() => _cashCtrl.text = '$q'),
                    child: Text('${q ~/ 1000}K'),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tiền thối lại khách:', style: TextStyle(color: kBrown, fontWeight: FontWeight.w600)),
                Text('${formatVnd(_change)} VND',
                    key: const Key('change-due'),
                    style: const TextStyle(color: kSuccess, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
          if (_method == 'VIETQR') ...[
            const SizedBox(height: 16),
            const Text('Khách quét mã VietQR để thanh toán. Đơn sẽ chờ xác nhận từ cổng thanh toán.',
                style: TextStyle(color: kMuted)),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: kDanger)),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: const Text('HỦY'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  key: const Key('confirm-payment'),
                  onPressed: _submitting ? null : _confirm,
                  child: _submitting
                      ? const SizedBox(
                          height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('XÁC NHẬN'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _methodTile(String code, String label, IconData icon) {
    final selected = _method == code;
    return InkWell(
      key: Key('method-$code'),
      onTap: () => setState(() => _method = code),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF6ECE3) : Colors.white,
          border: Border.all(color: selected ? kBrown : kBorder, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: kBrown),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: kBrown)),
          ],
        ),
      ),
    );
  }

  Widget _success(CheckoutResult r) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: kSuccess, size: 64),
            const SizedBox(height: 12),
            const Text('Tạo đơn thành công', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBrown)),
            const SizedBox(height: 6),
            Text(r.orderNumber, key: const Key('order-number'), style: const TextStyle(color: kMuted, fontSize: 16)),
            const SizedBox(height: 16),
            if (r.paymentMethod == 'CASH')
              Text('Tiền thối lại: ${formatVnd(r.changeDue)} VND', style: const TextStyle(color: kBrown)),
            if (r.paymentMethod == 'VIETQR' && r.qrContent != null)
              Text('Chờ thanh toán VietQR (${r.qrContent})', style: const TextStyle(color: kMuted)),
            const SizedBox(height: 28),
            ElevatedButton(
              key: const Key('new-order'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('VỀ MÀN BÁN HÀNG'),
            ),
          ],
        ),
      ),
    );
  }
}
