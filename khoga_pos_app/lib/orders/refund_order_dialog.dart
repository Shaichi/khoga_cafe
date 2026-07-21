import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../format.dart';

class RefundOrderDialog extends StatefulWidget {
  final num amount;
  
  const RefundOrderDialog({super.key, required this.amount});

  @override
  State<RefundOrderDialog> createState() => _RefundOrderDialogState();
}

class _RefundOrderDialogState extends State<RefundOrderDialog> {
  String _actionType = 'REFUND'; // 'REFUND' or 'COMP'
  String _refundLimit = 'FULL'; // 'FULL' or 'PARTIAL'
  String? _selectedReason;
  final _notesCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();

  final List<String> _reasons = [
    'Khách hàng phàn nàn chất lượng',
    'Làm sai món / sai topping',
    'Lý do khác'
  ];

  @override
  void dispose() {
    _notesCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _onPinPressed(String val) {
    if (_pinCtrl.text.length < 4) {
      setState(() {
        _pinCtrl.text += val;
      });
    }
  }

  void _onPinBackspace() {
    if (_pinCtrl.text.isNotEmpty) {
      setState(() {
        _pinCtrl.text = _pinCtrl.text.substring(0, _pinCtrl.text.length - 1);
      });
    }
  }

  void _onPinClear() {
    setState(() {
      _pinCtrl.text = '';
    });
  }

  void _submit() {
    if (_selectedReason == null || _pinCtrl.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền đủ thông tin và mã PIN')));
      return;
    }
    Navigator.of(context).pop({
      'type': _actionType == 'COMP' ? 'COMP_REMAKE' : 'REFUND',
      'reason': _selectedReason! + (_notesCtrl.text.isNotEmpty ? ' - ${_notesCtrl.text}' : ''),
      'smPin': _pinCtrl.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: 375,
        height: 729,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
          boxShadow: [
            BoxShadow(color: Color(0x26000000), blurRadius: 30, offset: Offset(0, -10))
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Hoàn Tiền / Đổi Trả Đơn',
                    style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 17.8, color: Color(0xFF2C1A11)),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: const Color(0xFFFAF6F2), borderRadius: BorderRadius.circular(16)),
                      alignment: Alignment.center,
                      child: const Text('×', style: TextStyle(fontFamily: 'Arial', fontSize: 18, color: Color(0xFF8C766C))),
                    ),
                  ),
                ],
              ),
            ),
            
            // Order Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text('Đơn hàng: ', style: TextStyle(fontFamily: 'Segoe UI', fontSize: 12, color: Color(0xFF8C766C))),
                  const Text('#011 ', style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF8C766C))), // Mocked number for now
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(4)),
                    child: const Text('Chờ lấy hàng', style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFFB78103))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Action Type
                    const Text('Loại hành động *', style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3D2314))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _radioOption('Hoàn tiền (Refund)', _actionType == 'REFUND', () => setState(() => _actionType = 'REFUND')),
                        const SizedBox(width: 15),
                        _radioOption('Làm lại món (Comp)', _actionType == 'COMP', () => setState(() => _actionType = 'COMP')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Refund Limit
                    const Text('Hạn mức hoàn trả *', style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3D2314))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _radioOption('Toàn bộ (${formatVnd(widget.amount)} đ)', _refundLimit == 'FULL', () => setState(() => _refundLimit = 'FULL')),
                        const SizedBox(width: 15),
                        _radioOption('Theo món (Từng phần)', _refundLimit == 'PARTIAL', () => setState(() => _refundLimit = 'PARTIAL')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFF0E6DF)),
                    const SizedBox(height: 16),
                    
                    // Reason
                    const Text('Lý do yêu cầu *', style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3D2314))),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 38,
                      child: DropdownButtonFormField<String>(
                        value: _selectedReason,
                        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF8C766C)),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFFAFAFA),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFEADDD3))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFC89D7C))),
                        ),
                        items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontFamily: 'Segoe UI', fontSize: 13, color: Color(0xFF2C1A11))))).toList(),
                        onChanged: (v) => setState(() => _selectedReason = v),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Notes
                    const Text('Ghi chú chi tiết', style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3D2314))),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 38,
                      child: TextField(
                        controller: _notesCtrl,
                        style: const TextStyle(fontFamily: 'Segoe UI', fontSize: 13, color: Color(0xFF2C1A11)),
                        decoration: InputDecoration(
                          hintText: 'Nhập ghi chú chi tiết nếu có...',
                          hintStyle: const TextStyle(fontFamily: 'Segoe UI', fontSize: 13, color: Color(0xFF8C766C)),
                          filled: true,
                          fillColor: const Color(0xFFFAFAFA),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFEADDD3))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFC89D7C))),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // PIN Pad
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDFAF7),
                        border: Border.all(color: const Color(0xFFC89D7C), style: BorderStyle.none),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      foregroundDecoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFC89D7C), width: 1), // fallback for dashed
                      ),
                      child: Column(
                        children: [
                          const Text('Xác thực của Quản lý', style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF8C766C))),
                          const SizedBox(height: 8),
                          // PIN dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (i) {
                              bool filled = i < _pinCtrl.text.length;
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: filled ? const Color(0xFFC89D7C) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFC89D7C), width: 2),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 16),
                          // Keypad
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: GridView.count(
                              crossAxisCount: 3,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 6,
                              crossAxisSpacing: 6,
                              childAspectRatio: 1.8,
                              children: [
                                _pinBtn('1', () => _onPinPressed('1')),
                                _pinBtn('2', () => _onPinPressed('2')),
                                _pinBtn('3', () => _onPinPressed('3')),
                                _pinBtn('4', () => _onPinPressed('4')),
                                _pinBtn('5', () => _onPinPressed('5')),
                                _pinBtn('6', () => _onPinPressed('6')),
                                _pinBtn('7', () => _onPinPressed('7')),
                                _pinBtn('8', () => _onPinPressed('8')),
                                _pinBtn('9', () => _onPinPressed('9')),
                                _pinBtn('Clear', _onPinClear, isAction: true),
                                _pinBtn('0', () => _onPinPressed('0')),
                                _pinBtn('⌫', _onPinBackspace, isAction: true),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Hoặc Đăng nhập bằng tài khoản SM',
                            style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFC89D7C), decoration: TextDecoration.underline),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Mã PIN test: 1234 hoặc 2580 | SM test: manager01 / 12345678', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF8C766C))),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            
            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFEADDD3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('HỦY BỎ', style: TextStyle(fontFamily: 'Arial', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3D2314))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3D2314),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _submit,
                        child: const Text('XÁC NHẬN', style: TextStyle(fontFamily: 'Arial', fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _radioOption(String text, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: selected ? const Color(0xFF3D2314) : const Color(0xFF8C766C), size: 18),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.w600, fontSize: 12.6, color: Color(0xFF2C1A11))),
        ],
      ),
    );
  }

  Widget _pinBtn(String text, VoidCallback onTap, {bool isAction = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: isAction ? const Color(0xFFFAF6F2) : Colors.white,
          border: Border.all(color: const Color(0xFFEADDD3)),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Segoe UI',
            fontWeight: FontWeight.bold,
            fontSize: isAction ? 11 : 14,
            color: const Color(0xFF3D2314),
          ),
        ),
      ),
    );
  }
}
