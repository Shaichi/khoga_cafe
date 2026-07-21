import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../auth/auth_controller.dart';
import '../theme.dart';

class ForcePasswordChangeScreen extends StatefulWidget {
  const ForcePasswordChangeScreen({super.key});

  @override
  State<ForcePasswordChangeScreen> createState() => _ForcePasswordChangeScreenState();
}

class _ForcePasswordChangeScreenState extends State<ForcePasswordChangeScreen> {
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final newPassword = _newPasswordCtrl.text;
    final confirmPassword = _confirmPasswordCtrl.text;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() => _error = 'Vui lòng nhập mật khẩu mới');
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _error = 'Mật khẩu xác nhận không khớp.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthController>();
      await auth.forcePasswordChange(newPassword);
      // The AuthGate in app.dart will automatically route the user away from this screen
      // because auth.mustChangePassword is now false.
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Lỗi đổi mật khẩu: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Đổi Mật Khẩu Bắt Buộc',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBrown),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Vì lý do bảo mật, bạn cần thay đổi mật khẩu tạm\nthời trước khi sử dụng hệ thống.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kMuted, height: 1.5, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDECEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF3C9C6)),
                      ),
                      child: Text(_error!, style: const TextStyle(color: kDanger, fontSize: 14)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF9F6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF5E6DC)),
                    ),
                    child: const Text(
                      'Mật khẩu mới yêu cầu tối thiểu 8 ký tự, bao gồm chữ hoa, chữ thường, chữ số và ký tự đặc biệt.',
                      style: TextStyle(color: kBrown, fontSize: 12, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Mật khẩu mới', style: TextStyle(color: kBrown, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newPasswordCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Mật khẩu mới',
                      hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: kGold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Xác nhận mật khẩu', style: TextStyle(color: kBrown, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _confirmPasswordCtrl,
                    obscureText: true,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: 'Xác nhận lại mật khẩu',
                      hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: kGold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBrown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text('ĐỔI MẬT KHẨU', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () => context.read<AuthController>().logout(),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Đăng xuất'),
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
