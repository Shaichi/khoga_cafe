import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/models.dart';
import '../api/voucher_api.dart';
import '../format.dart';
import '../theme.dart';
import 'cart_controller.dart';

class VoucherModal extends StatefulWidget {
  final CartController cart;
  final VoucherApi voucherApi;

  const VoucherModal({super.key, required this.cart, required this.voucherApi});

  @override
  State<VoucherModal> createState() => _VoucherModalState();
}

class _VoucherModalState extends State<VoucherModal> {
  late TextEditingController _voucherCtrl;
  List<VoucherLite>? _activeVouchers;
  String? _error;

  @override
  void initState() {
    super.initState();
    _voucherCtrl = TextEditingController(text: widget.cart.voucher?.code ?? '');

    widget.voucherApi
        .listActive()
        .then((list) {
          if (mounted) setState(() => _activeVouchers = list);
        })
        .catchError((_) {
          if (mounted) setState(() => _activeVouchers = []);
        });
  }

  @override
  void dispose() {
    _voucherCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final code = _voucherCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      widget.cart.clearVoucher();
      Navigator.of(context).pop();
      return;
    }

    final matched = _activeVouchers?.where((v) => v.code == code).firstOrNull;
    if (matched != null) {
      widget.cart.applyVoucher(matched);
      Navigator.of(context).pop();
    } else {
      setState(() {
        _error = 'Mã voucher không hợp lệ hoặc chưa hỗ trợ lookup';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 375),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 34, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.arrow_back,
                              color: Color(0xFF8C766C),
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const Text(
                        'Áp Dụng Voucher',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                          color: Color(0xFF2C1A11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Tạm tính
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Tạm tính giỏ hàng:',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 13,
                            color: Color(0xFF5C3826),
                          ),
                        ),
                      ),
                      Text(
                        '${formatVnd(widget.cart.subtotal)} VND',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF2C1A11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Input
                  const Text(
                    'Nhập mã giảm giá',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF5C3826),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('voucher-input'),
                    controller: _voucherCtrl,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [LengthLimitingTextInputFormatter(50)],
                    style: const TextStyle(
                      fontFamily: 'Arial',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF2C1A11),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ví dụ: COFFEE20',
                      hintStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.normal,
                        fontSize: 14,
                        color: Color(0xFF2C1A11),
                      ),
                      fillColor: const Color(0xFFFAFAFA),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      errorText: _error,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFEADDD3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: kGold, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: kDanger),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: kDanger, width: 2),
                      ),
                    ),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                  ),
                  const SizedBox(height: 24),
                  // List
                  const Text(
                    'Mã khuyến mãi hiện có',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF8C766C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_activeVouchers == null)
                    const Center(child: CircularProgressIndicator())
                  else if (_activeVouchers!.isEmpty)
                    const Text(
                      'Không có mã khuyến mãi khả dụng.',
                      style: TextStyle(color: kMuted, fontSize: 13),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _activeVouchers!.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final v = _activeVouchers![i];
                          return InkWell(
                            onTap: () =>
                                setState(() => _voucherCtrl.text = v.code),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDFDFD),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFEADDD3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          v.code,
                                          style: const TextStyle(
                                            fontFamily: 'Roboto',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Color(0xFF3D2314),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          v.description ?? 'Giảm giá',
                                          style: const TextStyle(
                                            fontFamily: 'Roboto',
                                            fontSize: 11,
                                            color: Color(0xFF8C766C),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      v.discountType == 'PERCENTAGE'
                                          ? 'GIẢM ${v.discountValue}%'
                                          : 'GIẢM ${formatVnd(v.discountValue / 1000)}K',
                                      style: const TextStyle(
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const Spacer(),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFEADDD3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size.fromHeight(50),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'HỦY',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF3D2314),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          key: const Key('promo-apply'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3D2314),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: _apply,
                          child: const Text(
                            'XÁC NHẬN',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.normal,
                              fontSize: 14,
                              color: Colors.white,
                            ),
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
