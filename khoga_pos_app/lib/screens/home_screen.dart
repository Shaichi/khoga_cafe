import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import '../theme.dart';

/// Placeholder post-login home. The shift dashboard + POS land in slices F3+.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
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
            const Card(
              child: ListTile(
                leading: Icon(Icons.point_of_sale, color: kBrown),
                title: Text('Bán hàng (POS)'),
                subtitle: Text('Mở ca & màn hình bán hàng — bước kế tiếp'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
