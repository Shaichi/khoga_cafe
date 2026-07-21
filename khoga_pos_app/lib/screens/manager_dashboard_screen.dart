import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../api/stock_api.dart';
import '../auth/auth_controller.dart';
import '../auth/logout_confirm_modal.dart';
import '../inventory/stock_list_screen.dart';
import '../screens/reports_hub_screen.dart';
import '../staff/attendance_screen.dart';
import '../staff/schedule_screen.dart';
import '../staff/staff_list_screen.dart';
import '../theme.dart';
import 'branch_settings_screen.dart';
import 'manager_order_history_screen.dart';
import '../profile/profile_screen.dart';

class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Header
              const Text(
                'Store Manager',
                style: TextStyle(
                  fontFamily: 'Segoe UI',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kBrownDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                auth.profile?.storeName ?? 'Khoga',
                style: const TextStyle(
                  fontFamily: 'Segoe UI',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: kMuted,
                ),
              ),
              const SizedBox(height: 32),

              // Grid Menu
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio:
                    1.6, // Adjusted to match the visual proportion (156x94 from Figma)
                children: [
                  _buildMenuCard(
                    key: const Key('inventory-action'),
                    context: context,
                    icon: Icons.inventory_2_outlined,
                    label: 'Kho Hàng',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StockListScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    key: const Key('staff-action'),
                    context: context,
                    icon: Icons.people_outline,
                    label: 'Nhân Viên',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StaffListScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    key: const Key('schedule-action'),
                    context: context,
                    icon: Icons.calendar_month_outlined,
                    label: 'Lịch Làm Việc',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ScheduleScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    key: const Key('attendance-action'),
                    context: context,
                    icon: Icons.how_to_reg,
                    label: 'Điểm Danh',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AttendanceScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context: context,
                    icon: Icons.bar_chart,
                    label: 'Báo Cáo',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ReportsHubScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuCard(
                    context: context,
                    icon: Icons.receipt_long_outlined,
                    label: 'Lịch Sử Đơn',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ManagerOrderHistoryScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

            // Alerts / Settings widgets
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const LowStockAlertWidget(),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.person_outline,
                    iconColor: kMuted,
                    title: 'Tài khoản & Bảo mật',
                    subtitle: 'Đổi email, số điện thoại, mật khẩu',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.settings_outlined,
                    iconColor: kMuted,
                    title: 'Cấu hình chi nhánh',
                    subtitle: 'Cài đặt máy in POS',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BranchSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: () => _showLogoutDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrown,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'ĐĂNG XUẤT',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    Key? key,
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: kGold, size: 28),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Segoe UI',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: kBrown,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Segoe UI',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: kBrownDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Segoe UI',
                      fontSize: 12,
                      color: kMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kMuted),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => const LogoutConfirmModal(),
    );
    if (confirm == true && context.mounted) {
      context.read<AuthController>().logout();
    }
  }
}

class LowStockAlertWidget extends StatefulWidget {
  const LowStockAlertWidget({super.key});

  @override
  State<LowStockAlertWidget> createState() => _LowStockAlertWidgetState();
}

class _LowStockAlertWidgetState extends State<LowStockAlertWidget> {
  late final StockApi _api;
  int _lowStockCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _api = StockApi(context.read<ApiClient>());
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final list = await _api.list(lowStock: true);
      if (mounted) {
        setState(() {
          _lowStockCount = list.length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _loading
        ? 'Đang kiểm tra...'
        : _lowStockCount > 0
        ? '$_lowStockCount nguyên liệu sắp hết kho'
        : 'Kho nguyên liệu ổn định';

    return InkWell(
      onTap: () async {
        if (_loading) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const StockListScreen(initialLowOnly: true),
          ),
        );
        _load(); // Refresh on back
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: _lowStockCount > 0 ? kDanger : kSuccess,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cảnh báo tồn kho',
                    style: TextStyle(
                      fontFamily: 'Segoe UI',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: kBrownDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Segoe UI',
                      fontSize: 12,
                      color: kMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kMuted),
          ],
        ),
      ),
    );
  }
}
