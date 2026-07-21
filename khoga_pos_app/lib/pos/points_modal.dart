import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../theme.dart';
import 'cart_controller.dart';

class PointsModal extends StatefulWidget {
  final CartController cart;

  const PointsModal({super.key, required this.cart});

  @override
  State<PointsModal> createState() => _PointsModalState();
}

class _PointsModalState extends State<PointsModal> {
  late TextEditingController _pointsCtrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pointsCtrl = TextEditingController(
      text: widget.cart.redeemPoints > 0
          ? widget.cart.redeemPoints.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _pointsCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    if (widget.cart.customer == null) return;

    final text = _pointsCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final p = int.tryParse(text) ?? 0;

    if (p > widget.cart.customer!.points) {
      setState(() => _error = 'Điểm quy đổi vượt quá điểm khả dụng');
      return;
    }

    widget.cart.setRedeemPoints(p);
    Navigator.of(context).pop();
  }


  @override
  Widget build(BuildContext context) {
    final customer = widget.cart.customer;
    if (customer == null) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Vui lòng gắn hội viên trước'),
        ),
      );
    }

    final p =
        int.tryParse(_pointsCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final discount = p * 1000;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 375),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Color(0xFF8C766C),
                                  size: 20,
                                ),
                              ),
                            ),
                            const Text(
                              'Đổi Điểm Hội Viên',
                              style: TextStyle(
                                fontFamily: 'Segoe UI',
                                fontWeight: FontWeight.bold,
                                fontSize: 19,
                                color: Color(0xFF2C1A11),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Tên khách hàng
                        const Text(
                          'Tên khách hàng',
                          style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF5C3826)),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5EEE8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            customer.fullName,
                            style: const TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF3D2314)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Hạng thẻ hội viên
                        const Text(
                          'Hạng thẻ hội viên',
                          style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF5C3826)),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5EEE8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Gold (Được quyền quy đổi)', // Hardcoded like Figma for now
                            style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF3D2314)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Điểm tích lũy khả dụng
                        const Text(
                          'Điểm tích lũy khả dụng',
                          style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF5C3826)),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5EEE8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${formatVnd(customer.points)} điểm',
                            style: const TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF3D2314)),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Số điểm quy đổi
                        const Text(
                          'Số điểm quy đổi *',
                          style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF5C3826)),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 44,
                          child: TextField(
                            key: const Key('points-input'),
                            controller: _pointsCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: const TextStyle(
                              fontFamily: 'Arial',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF2C1A11),
                            ),
                            decoration: InputDecoration(
                              fillColor: const Color(0xFFFAFAFA),
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 0,
                              ),
                              errorText: _error,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFEADDD3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFC89D7C), width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFB3261E)),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFB3261E), width: 2),
                              ),
                            ),
                            onChanged: (val) {
                              if (_error != null) setState(() => _error = null);
                              setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Discount preview
                        Container(
                          height: 27,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Chiết khấu quy đổi: -${formatVnd(discount)} VND',
                            style: const TextStyle(
                              fontFamily: 'Segoe UI',
                              fontWeight: FontWeight.bold,
                              fontSize: 12.9,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Bottom Buttons
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFEADDD3)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'HỦY',
                              style: TextStyle(
                                fontFamily: 'Segoe UI',
                                fontWeight: FontWeight.bold,
                                fontSize: 13.8,
                                color: Color(0xFF3D2314),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3D2314),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _apply,
                            child: const Text(
                              'XÁC NHẬN',
                              style: TextStyle(
                                fontFamily: 'Arial',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
