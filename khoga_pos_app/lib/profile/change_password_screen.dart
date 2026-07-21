import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../auth/auth_controller.dart';
import '../theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  
  bool _submitting = false;
  String? _error;
  bool _done = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_current.text.isEmpty || _next.text.isEmpty || _confirm.text.isEmpty) {
      setState(() => _error = 'Vui lòng nhập đầy đủ thông tin');
      return;
    }
    if (_next.text != _confirm.text) {
      setState(() => _error = 'Mật khẩu xác nhận không khớp');
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      await context.read<AuthController>().changePassword(_current.text, _next.text);
      if (mounted) setState(() => _done = true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Không kết nối được máy chủ');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: _done ? _successView() : _formView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Đổi Mật Khẩu',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBrownDark),
        ),
        const SizedBox(height: 12),
        const Text(
          'Thay đổi mật khẩu tài khoản đang hoạt động của bạn.',
          textAlign: TextAlign.center,
          style: TextStyle(color: kMuted, fontSize: 13),
        ),
        const SizedBox(height: 32),
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
        _field('Mật khẩu hiện tại', _current, 'Mật khẩu hiện tại', const Key('current-password')),
        const SizedBox(height: 20),
        _field('Mật khẩu mới', _next, 'Mật khẩu mới', const Key('new-password')),
        const SizedBox(height: 20),
        _field('Xác nhận mật khẩu mới', _confirm, 'Nhập lại mật khẩu mới', const Key('confirm-password')),
        const SizedBox(height: 40),
        ElevatedButton(
          key: const Key('change-pw-submit'),
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: kBrownDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _submitting
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('CẬP NHẬT MẬT KHẨU', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy bỏ', style: TextStyle(color: kBrownDark, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _successView() {
    return Column(
      key: const Key('change-pw-success'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, color: kSuccess, size: 80),
        const SizedBox(height: 24),
        const Text(
          'Đổi mật khẩu thành công',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBrownDark),
        ),
        const SizedBox(height: 12),
        const Text(
          'Mật khẩu của bạn đã được cập nhật an toàn. Vui lòng sử dụng mật khẩu mới cho các lần đăng nhập tiếp theo.',
          textAlign: TextAlign.center,
          style: TextStyle(color: kMuted, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: kBrownDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('QUAY LẠI', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController c, String hint, Key key) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBrownDark)),
        const SizedBox(height: 8),
        TextField(
          key: key,
          controller: c,
          obscureText: true,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: kMuted, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: Colors.white,
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
              borderSide: const BorderSide(color: kBrown),
            ),
          ),
        ),
      ],
    );
  }
}
