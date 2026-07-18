import 'package:flutter/material.dart';

import '../api/models.dart';
import '../theme.dart';

class PrintStickerDialog extends StatelessWidget {
  final OrderDetail order;

  const PrintStickerDialog({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('In Nhãn Dán Ly (Sticker)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBrown)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F7F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DefaultTextStyle(
                style: const TextStyle(fontFamily: 'Courier', fontSize: 13, color: Colors.black87, height: 1.5),
                child: Column(
                  children: [
                    const Text('=== KHOGA CAFÉ ==='),
                    if (order.items.isNotEmpty) ...[
                      Text('Món: ${order.items.first.menuItemName}'),
                      Text('Đơn: ${order.orderNumber}'),
                      if (order.items.first.toppings.isNotEmpty)
                        Text('Yêu cầu: ${order.items.first.toppings.map((t) => t.name).join(', ')}'),
                    ],
                    Text('Trạng thái: ${order.orderType}'),
                    const Text('------------------'),
                    const Text('* IN NHÃN HOÀN THÀNH *'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kDanger,
                      side: const BorderSide(color: kDanger),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('BỎ QUA', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kSuccess,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      // Simulating print delay
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã gửi lệnh in đến máy in tem.'), backgroundColor: kSuccess),
                      );
                    },
                    child: const Text('IN NHÃN DÁN (PRINT)', style: TextStyle(fontWeight: FontWeight.bold)),
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
