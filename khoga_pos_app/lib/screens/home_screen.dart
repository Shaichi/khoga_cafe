import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import '../inventory/stock_list_screen.dart';
import '../orders/barista_queue_screen.dart';
import '../orders/order_history_screen.dart';
import '../pos/close_shift_screen.dart';
import '../pos/pos_screen.dart';
import '../pos/shift_controller.dart';
import '../profile/profile_screen.dart';
import '../staff/attendance_screen.dart';
import '../staff/schedule_screen.dart';
import '../theme.dart';

/// Post-login / post-open-shift home. POS checkout lands in slice F4.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final shift = context.watch<ShiftController>().active;
    final profile = auth.profile;
    final isManager = profile?.role == 'STORE_MANAGER';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrown,
        foregroundColor: Colors.white,
        title: const Text('Khoga POS'),
        actions: [
          IconButton(
            key: const Key('profile-action'),
            tooltip: 'Hồ sơ',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            ),
          ),
          IconButton(onPressed: auth.logout, icon: const Icon(Icons.logout), tooltip: 'Đăng xuất'),
        ],
      ),
      body: SingleChildScrollView(
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
            Card(
              child: ListTile(
                key: const Key('order-history-action'),
                leading: const Icon(Icons.receipt_long_outlined, color: kBrown),
                title: const Text('Lịch sử đơn hàng'),
                subtitle: const Text('Xem & tra cứu đơn đã tạo'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const OrderHistoryScreen()),
                ),
              ),
            ),
            Card(
              child: ListTile(
                key: const Key('queue-action'),
                leading: const Icon(Icons.local_cafe_outlined, color: kBrown),
                title: const Text('Hàng đợi pha chế'),
                subtitle: const Text('Đơn đang chờ & cập nhật trạng thái'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const BaristaQueueScreen()),
                ),
              ),
            ),
            Card(
              child: ListTile(
                key: const Key('attendance-action'),
                leading: const Icon(Icons.badge_outlined, color: kBrown),
                title: const Text('Chấm công'),
                subtitle: const Text('Vào ca / tan ca bằng mã PIN'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AttendanceScreen()),
                ),
              ),
            ),
            if (isManager) ...[
              const SizedBox(height: 16),
              const Text('Quản lý chi nhánh', style: TextStyle(color: kMuted, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  key: const Key('inventory-action'),
                  leading: const Icon(Icons.inventory_2_outlined, color: kBrown),
                  title: const Text('Kho chi nhánh'),
                  subtitle: const Text('Tồn kho, nhập hàng, lịch sử'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const StockListScreen()),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  key: const Key('schedule-action'),
                  leading: const Icon(Icons.calendar_month_outlined, color: kBrown),
                  title: const Text('Lịch làm việc'),
                  subtitle: const Text('Ca làm & nhân sự chi nhánh'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const ScheduleScreen()),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
