import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../auth/auth_controller.dart';
import '../theme.dart';

/// Screen 08 — change password (UC-06). Requires the current password and a new
/// one (confirmed). The backend enforces the strong-password policy.
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
    if (_current.text.isEmpty || _next.text.isEmpty) {
      setState(() => _error = 'Vui lòng nhập đầy đủ mật khẩu');
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
      appBar: AppBar(
        backgroundColor: kBrown,
        foregroundColor: Colors.white,
        title: const Text('Đổi mật khẩu'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: _done ? _success() : _form(),
          ),
        ),
      ),
    );
  }

  Widget _form() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            Text(_error!, key: const Key('change-pw-error'), style: const TextStyle(color: kDanger)),
            const SizedBox(height: 12),
          ],
          _field('Mật khẩu hiện tại *', _current, const Key('current-password')),
          const SizedBox(height: 16),
          _field('Mật khẩu mới *', _next, const Key('new-password')),
          const SizedBox(height: 16),
          _field('Xác nhận mật khẩu mới *', _confirm, const Key('confirm-password')),
          const SizedBox(height: 28),
          ElevatedButton(
            key: const Key('change-pw-submit'),
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('ĐỔI MẬT KHẨU'),
          ),
        ],
      );

  Widget _success() => Column(
        key: const Key('change-pw-success'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: kSuccess, size: 64),
          const SizedBox(height: 12),
          const Text('Đổi mật khẩu thành công', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBrown)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('XONG')),
        ],
      );

  Widget _field(String label, TextEditingController c, Key key) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBrown)),
          const SizedBox(height: 8),
          TextField(key: key, controller: c, obscureText: true, inputFormatters: [LengthLimitingTextInputFormatter(255)]),
        ],
      );
}
