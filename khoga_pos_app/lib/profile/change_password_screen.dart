import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../auth/auth_controller.dart';
import '../theme.dart';

/// Screen — "Đổi Mật Khẩu" per Figma Node 28:232.
/// Dedicated page allowing active users to update their password.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNext = true;
  bool _obscureConfirm = true;

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
      setState(() => _error = 'Vui lòng nhập đầy đủ các trường mật khẩu');
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C1A11),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    maxWidth: 380,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: IntrinsicHeight(
                      child: _done ? _buildSuccess() : _buildForm(),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Đổi Mật Khẩu',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Segoe UI',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C1A11),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Thay đổi mật khẩu tài khoản đang hoạt động của bạn.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Segoe UI',
            fontSize: 14,
            height: 1.5,
            color: Color(0xFF8C766C),
          ),
        ),
        const SizedBox(height: 32),

        if (_error != null) ...[
          Container(
            key: const Key('change-pw-error'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kDanger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kDanger.withValues(alpha: 0.3)),
            ),
            child: Text(
              _error!,
              style: const TextStyle(color: kDanger, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Field 1: Current Password
        _buildPasswordField(
          label: 'Mật khẩu hiện tại',
          placeholder: 'Mật khẩu hiện tại',
          controller: _current,
          key: const Key('current-password'),
          obscure: _obscureCurrent,
          onToggleObscure: () => setState(() => _obscureCurrent = !_obscureCurrent),
        ),
        const SizedBox(height: 20),

        // Field 2: New Password
        _buildPasswordField(
          label: 'Mật khẩu mới',
          placeholder: 'Mật khẩu mới',
          controller: _next,
          key: const Key('new-password'),
          obscure: _obscureNext,
          onToggleObscure: () => setState(() => _obscureNext = !_obscureNext),
        ),
        const SizedBox(height: 20),

        // Field 3: Confirm New Password
        _buildPasswordField(
          label: 'Xác nhận mật khẩu mới',
          placeholder: 'Nhập lại mật khẩu mới',
          controller: _confirm,
          key: const Key('confirm-password'),
          obscure: _obscureConfirm,
          onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),

        // Spacer to push actions to bottom
        const Spacer(),
        const SizedBox(height: 40),

        // Primary Button: CẬP NHẬT MẬT KHẨU
        SizedBox(
          height: 50,
          child: ElevatedButton(
            key: const Key('change-pw-submit'),
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3D2314),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'CẬP NHẬT MẬT KHẨU',
                    style: TextStyle(
                      fontFamily: 'Arial',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),

        // Secondary link: Hủy bỏ
        Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Text(
                'Hủy bỏ',
                style: TextStyle(
                  fontFamily: 'Segoe UI',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8C766C),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String placeholder,
    required TextEditingController controller,
    required Key key,
    required bool obscure,
    required VoidCallback onToggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Segoe UI',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5C3826),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: key,
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(
              fontFamily: 'Arial',
              fontSize: 15,
              color: Color(0xFF9E9E9E),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: const Color(0xFFFDFDFD),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5DBCF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5DBCF)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3D2314), width: 1.5),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF8C766C),
                size: 20,
              ),
              onPressed: onToggleObscure,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      key: const Key('change-pw-success'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 30),
        const Icon(Icons.check_circle_rounded, color: kSuccess, size: 68),
        const SizedBox(height: 16),
        const Text(
          'Đổi mật khẩu thành công',
          style: TextStyle(
            fontFamily: 'Segoe UI',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C1A11),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Mật khẩu mới của bạn đã được cập nhật.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF8C766C), fontSize: 14),
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3D2314),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'QUAY LẠI',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}
