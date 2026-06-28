import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import '../pos/close_shift_screen.dart';
import '../pos/pos_screen.dart';
import '../pos/shift_controller.dart';
import '../theme.dart';

/// Post-login / post-open-shift home. POS checkout lands in slice F4.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final shift = context.watch<ShiftController>().active;
    final profile = auth.profile;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrown,
        foregroundColor: Colors.white,
        title: const Text('Khoga POS'),
        actions: [
          IconButton(onPressed: auth.logout, icon: const Icon(Icons.logout), tooltip: 'Đăng xuất'),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Xin chào,', style: TextStyle(color: kMuted, fontSize: 14)),
            Text(profile?.fullName ?? '',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kBrown)),
            const SizedBox(height: 24),
            if (shift != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.point_of_sale, color: kBrown),
                  title: Text('Ca đang mở · ${shift.posRegisterId}'),
                  subtitle: Text('Tiền đầu ca: ${shift.startingCash} đ'),
                  trailing: TextButton.icon(
                    key: const Key('close-shift-action'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const CloseShiftScreen()),
                    ),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Đóng ca'),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.shopping_cart_outlined, color: kBrown),
                title: const Text('Màn hình bán hàng (POS)'),
                subtitle: const Text('Lưới món & giỏ hàng'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const PosScreen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
