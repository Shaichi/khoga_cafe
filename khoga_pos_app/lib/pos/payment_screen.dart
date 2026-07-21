import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../api/api_client.dart';
import '../api/checkout_api.dart';
import '../api/models.dart';
import '../api/order_api.dart';
import '../format.dart';
import '../theme.dart';
import '../auth/auth_controller.dart';
import 'cart_controller.dart';

/// Screen 38 — "Payment Checkout Modal". Previews the breakdown, lets the cashier
/// pick a method (cash/card/VietQR) and, for cash, the amount tendered, then
/// submits the order. CASH/CARD confirm immediately; VietQR shows the returned QR
/// and polls the order until the gateway callback flips it to PAID (BR-84/85).
class PaymentScreen extends StatefulWidget {
  /// How often to poll the order's payment status while awaiting the VietQR
  /// gateway callback. Overridable so tests can drive it fast.
  final Duration pollInterval;
  const PaymentScreen({super.key, this.pollInterval = const Duration(seconds: 3)});

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
  late final OrderApi _orderApi;
  late final CartController _cart;
  final _cashCtrl = TextEditingController();

  String _method = 'CASH';
  CheckoutBreakdown? _breakdown;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  CheckoutResult? _result;
  CheckoutResult? _awaiting;
  bool _qrExpired = false;
  int _retryCount = 0; // VietQR order created, waiting for the gateway callback
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _api = CheckoutApi(context.read<ApiClient>());
    _orderApi = OrderApi(context.read<ApiClient>());
    _cart = context.read<CartController>();
    _loadPreview();
  }

  @override
  void dispose() {
    _disposed = true;
    _cashCtrl.dispose();
    super.dispose();
  }

  CheckoutRequestData _request({num? cashReceived}) => CheckoutRequestData(
        lines: _cart.lines,
        paymentMethod: _method,
        orderType: _cart.orderType,
        cashReceived: cashReceived,
        customerId: _cart.customer?.id,
        voucherCode: _cart.voucherCode,
        redeemPoints: _cart.redeemPoints,
      );

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
      if (!mounted) return;
      if (_method == 'VIETQR' && res.paymentStatus != 'PAID') {
        // Order created, awaiting the gateway callback — show the QR and poll.
        setState(() {
          _awaiting = res;
          _qrExpired = false;
          _retryCount = 0;
        });
        _pollPayment(res.orderId);
      } else {
        setState(() => _result = res);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Thanh toán thất bại');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Polls the order until the VietQR gateway marks it PAID (BR-85), then flips to
  /// the success view. Stops on dispose or when the awaiting order is dismissed.
  /// Added 60s timeout (UC-51).
  Future<void> _pollPayment(String orderId) async {
    final startTime = DateTime.now();
    while (!_disposed && _awaiting != null && !_qrExpired) {
      await Future<void>.delayed(widget.pollInterval);
      if (_disposed || _awaiting == null) return;
      if (DateTime.now().difference(startTime).inSeconds >= 60) {
        if (mounted) setState(() => _qrExpired = true);
        return;
      }
      try {
        final order = await _orderApi.detail(orderId);
        if (order.paymentStatus == 'PAID') {
          if (!_disposed) {
            setState(() {
              _result = _awaiting;
              _awaiting = null;
            });
          }
          return;
        }
      } catch (_) {
        // transient failure — keep polling
      }
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
            : _awaiting != null
                ? _qrAwaiting(_awaiting!)
                : _loading
                    ? const Center(child: Text('Đang tải hóa đơn…'))
                    : _form(),
      ),
    );
  }

  Widget _form() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
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
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < _methods.length; i++) ...[
                  Expanded(child: _methodTile(_methods[i].$1, _methods[i].$2, _methods[i].$3)),
                  if (i < _methods.length - 1) const SizedBox(width: 10),
                ],
              ],
            ),
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
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: kBorder)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton(
                onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: const Text('HỦY'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                key: const Key('confirm-payment'),
                onPressed: _submitting ? null : _confirm,
                child: _submitting
                    ? const SizedBox(
                        height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('XÁC NHẬN'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _methodTile(String code, String label, IconData icon) {
    final selected = _method == code;
    return InkWell(
      key: Key('method-$code'),
      onTap: () => setState(() => _method = code),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF6ECE3) : Colors.white,
          border: Border.all(color: selected ? kBrown : kBorder, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: kBrown),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: kBrown)),
          ],
        ),
      ),
    );
  }

  /// Renders the VietQR code the customer scans. The gateway may return either a
  /// ready-made image (base64 `data:image` URL → shown directly) or the raw
  /// EMVCo payload string (→ rendered into a scannable QR with qr_flutter).
  Widget _qrWidget(String? content) {
    if (content == null || content.isEmpty) {
      return const Icon(Icons.qr_code_2, color: kBrown, size: 96);
    }
    if (content.startsWith('data:image')) {
      final comma = content.indexOf(',');
      if (comma != -1) {
        try {
          return Image.memory(base64Decode(content.substring(comma + 1)),
              key: const Key('vietqr-image'), width: 220, height: 220, gaplessPlayback: true);
        } catch (_) {
          // malformed data URL — fall through to QR generation
        }
      }
    }
    return QrImageView(
      key: const Key('vietqr-image'),
      data: content,
      version: QrVersions.auto,
      size: 220,
      backgroundColor: Colors.white,
    );
  }

  Widget _qrAwaiting(CheckoutResult r) {
    return Center(
      key: const Key('qr-awaiting'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _qrWidget(r.qrContent),
            const SizedBox(height: 12),
            Text(r.orderNumber, key: const Key('order-number'), style: const TextStyle(fontSize: 16, color: kMuted)),
            const SizedBox(height: 6),
            Text('${formatVnd(r.breakdown.netTotalPayable)} VND',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBrown)),
            const SizedBox(height: 16),
            const Text('Khách quét mã VietQR để thanh toán.', style: TextStyle(color: kMuted)),
            const SizedBox(height: 20),
            if (_qrExpired) ...[
              const Text('Hết thời gian chờ (60s)', style: TextStyle(color: kDanger, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                key: const Key('retry-qr'),
                icon: const Icon(Icons.refresh),
                label: const Text('LÀM MỚI (RETRY)'),
                onPressed: () {
                  setState(() {
                    _retryCount++;
                    _qrExpired = false;
                  });
                  _pollPayment(r.orderId);
                },
              ),
              if (_retryCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Số lần thử lại: $_retryCount', style: const TextStyle(color: kMuted, fontSize: 12)),
                ),
            ] else ...[
              const SizedBox(
                height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kBrown)),
              const SizedBox(height: 12),
              const Text('Đang chờ xác nhận từ cổng thanh toán…',
                  style: TextStyle(color: kMuted, fontStyle: FontStyle.italic)),
              if (_retryCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Số lần thử lại: $_retryCount', style: const TextStyle(color: kMuted, fontSize: 12)),
                ),
            ],
            const SizedBox(height: 24),
            TextButton(
              key: const Key('cancel-awaiting'),
              onPressed: () => setState(() => _awaiting = null),
              child: const Text('Hủy chờ & quay lại', style: TextStyle(color: kGold, fontWeight: FontWeight.bold)),
            ),
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
            if (r.paymentMethod == 'VIETQR')
              const Text('Đã thanh toán VietQR', style: TextStyle(color: kSuccess, fontWeight: FontWeight.w600)),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              icon: const Icon(Icons.print),
              label: const Text('IN HÓA ĐƠN'),
              onPressed: () => _printInvoice(r),
            ),
            const SizedBox(height: 12),
            TextButton(
              key: const Key('new-order'),
              onPressed: () {
                _cart.clear();
                Navigator.of(context).pop();
              },
              child: const Text('VỀ MÀN BÁN HÀNG'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printInvoice(CheckoutResult r) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final order = await _orderApi.detail(r.orderId);
      if (!mounted) return;
      Navigator.pop(context); // close loading
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
                    Text('Thuế VAT gồm trong giá (10%):', style: TextStyle(fontSize: 11, color: kMuted)),
                    Text('${formatVnd((order.total * 10 / 110).round())} đ', style: TextStyle(fontSize: 11, color: kMuted)),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Thanh toán bằng:'),
                    Text(_methodLabel(order.paymentMethod), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Xin cảm ơn quý khách!\nHẹn gặp lại quý khách lần sau.',
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
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close loading
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi tải hóa đơn')));
    }
  }

  String _methodLabel(String method) => switch (method) {
        'CASH' => 'TIỀN MẶT',
        'CARD' => 'THẺ (ATM/CREDIT)',
        'VIETQR' => 'CHUYỂN KHOẢN (VIETQR)',
        _ => method,
      };
}
