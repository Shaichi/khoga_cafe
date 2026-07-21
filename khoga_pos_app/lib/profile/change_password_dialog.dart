import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../auth/auth_controller.dart';
import '../theme.dart';

Future<void> showChangePasswordDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => const _ChangePasswordDialog(),
  );
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        child: _done ? _success() : _form(),
      ),
    );
  }

  Widget _form() => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Đổi Mật Khẩu',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: kBrownDark,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Thay đổi mật khẩu tài khoản đang hoạt động của bạn.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: kMuted,
            ),
          ),
          const SizedBox(height: 24),
          if (_error != null) ...[
            Text(_error!, key: const Key('change-pw-error'), style: const TextStyle(color: kDanger)),
            const SizedBox(height: 12),
          ],
          _field('Mật khẩu hiện tại', _current, 'Mật khẩu hiện tại', const Key('current-password')),
          const SizedBox(height: 16),
          _field('Mật khẩu mới', _next, 'Mật khẩu mới', const Key('new-password')),
          const SizedBox(height: 16),
          _field('Xác nhận mật khẩu mới', _confirm, 'Nhập lại mật khẩu mới', const Key('confirm-password')),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('change-pw-submit'),
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrownDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _submitting
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('CẬP NHẬT MẬT KHẨU', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Hủy bỏ',
              style: TextStyle(color: kMuted, fontWeight: FontWeight.bold),
            ),
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
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(backgroundColor: kBrownDark, foregroundColor: Colors.white),
            child: const Text('XONG'),
          ),
        ],
      );

  Widget _field(String label, TextEditingController c, String hint, Key key) => Column(
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
                borderSide: const BorderSide(color: kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: kBorder),
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
