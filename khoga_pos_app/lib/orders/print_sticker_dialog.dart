import 'package:flutter/material.dart';

import '../api/models.dart';

/// Print Sticker Dialog — redesigned to match Figma Node 176:512.
class PrintStickerDialog extends StatelessWidget {
  final OrderDetail order;

  const PrintStickerDialog({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final rawNum = order.orderNumber;
    final formattedNum = rawNum.length >= 3
        ? rawNum.substring(rawNum.length - 3)
        : rawNum.padLeft(3, '0');

    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final itemName = firstItem?.menuItemName ?? 'Espresso';
    final toppingsText = (firstItem?.toppings ?? []).map((t) => t.name).join(', ');
    final reqText = toppingsText.isNotEmpty ? toppingsText : 'Không đường';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 380,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.15),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title per Figma 176:512
            const Text(
              'In Nhãn Dán Ly (Sticker)',
              style: TextStyle(
                fontFamily: 'Segoe UI',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C1A11),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Sticker Ticket Preview Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEADDD3)),
              ),
              child: Column(
                children: [
                  const Text(
                    '=== KHOGA CAFÉ ===',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C1A11),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Món: $itemName',
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 13,
                      color: Color(0xFF2C1A11),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Đơn: #$formattedNum',
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 13,
                      color: Color(0xFF2C1A11),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Yêu cầu: $reqText',
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 13,
                      color: Color(0xFF2C1A11),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Text(
                    'STK: STK-02',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 13,
                      color: Color(0xFF2C1A11),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '------------------',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 13,
                      color: Color(0xFF8C766C),
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '* IN NHÃN HOÀN THÀNH *',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C1A11),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons per Figma 176:512
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFCF6679),
                        side: const BorderSide(color: Color(0x66CF6679)),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'BỎ QUA',
                        style: TextStyle(
                          fontFamily: 'Segoe UI',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã gửi lệnh in đến máy in tem.'),
                            backgroundColor: Color(0xFF2E7D32),
                          ),
                        );
                      },
                      child: const Text(
                        'IN NHÃN DÁN (PRINT)',
                        style: TextStyle(
                          fontFamily: 'Arial',
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
