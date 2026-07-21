import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../auth/auth_controller.dart';
import '../auth/logout_dialog.dart';
import '../theme.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _getInitials(String name) {
    if (name.isEmpty) return 'NV';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final p = auth.profile;
    if (p == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: kBrownDark,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Thông Tin Cá Nhân',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: kBrownDark,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFFE5D5C5),
                    child: Text(
                      _getInitials(p.fullName),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: kBrownDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildRow('Họ và tên', p.fullName),
                  _buildRow('Tên đăng nhập', p.username),
                  _buildRow('Vai trò', p.role),
                  _buildRow('Chi nhánh', 'Nguyễn Du Branch'), // Placeholder, could use p.storeId mapping
                  _buildRow('Email', p.email ?? 'Chưa cập nhật'),
                  _buildRow('Số điện thoại', p.phone ?? 'Chưa cập nhật'),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kBrownDark,
                        side: const BorderSide(color: kBorder),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Chỉnh sửa thông tin', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kBrownDark,
                        side: const BorderSide(color: kBorder),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        final confirm = await showLogoutDialog(context);
                        if (confirm == true && context.mounted) {
                          auth.logout();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kDanger,
                        side: const BorderSide(color: Color(0xFFFDECEB)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: kMuted),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: kBrownDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF5EFEA)),
      ],
    );
  }
}
