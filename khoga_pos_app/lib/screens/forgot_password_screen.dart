import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/auth_api.dart';
import '../theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  int _step = 0; // 0 = email, 1 = otp, 2 = new password
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  AuthApi get _authApi => Provider.of<AuthApi>(context, listen: false);

  Future<void> _submitEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Vui lòng nhập email');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _authApi.forgotPassword(email);
      if (mounted) {
        setState(() {
          _step = 1;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Không thể gửi OTP. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitOtp() async {
    final email = _emailCtrl.text.trim();
    final otp = _otpCtrl.text.trim();
    if (otp.isEmpty) {
      setState(() => _error = 'Vui lòng nhập OTP');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _authApi.verifyOtp(email, otp);
      if (mounted) {
        setState(() {
          _step = 2;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Không thể xác thực OTP. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitNewPassword() async {
    final email = _emailCtrl.text.trim();
    final otp = _otpCtrl.text.trim();
    final newPassword = _newPasswordCtrl.text;
    final confirmPassword = _confirmPasswordCtrl.text;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() => _error = 'Vui lòng nhập mật khẩu mới');
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _error = 'Confirm password does not match the new password.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _authApi.resetPassword(email, otp, newPassword);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Đổi mật khẩu thành công! Vui lòng đăng nhập lại.'),
          backgroundColor: kSuccess,
        ));
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Không thể đổi mật khẩu. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildEmailStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Nhập email đã đăng ký:', style: TextStyle(color: kBrown, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'VD: admin@khoga.com'),
          onSubmitted: (_) => _submitEmail(),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _submitting ? null : _submitEmail,
          child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text('GỬI OTP'),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Một mã OTP đã được gửi đến email của bạn.', style: TextStyle(color: kMuted)),
        const SizedBox(height: 16),
        const Text('Mã xác thực (OTP)', style: TextStyle(color: kBrown, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(hintText: '123456'),
          onSubmitted: (_) => _submitOtp(),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _submitting ? null : _submitOtp,
          child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text('XÁC NHẬN'),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Mật khẩu mới', style: TextStyle(color: kBrown, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _newPasswordCtrl,
          obscureText: true,
        ),
        const SizedBox(height: 16),
        const Text('Xác nhận mật khẩu mới', style: TextStyle(color: kBrown, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmPasswordCtrl,
          obscureText: true,
          onSubmitted: (_) => _submitNewPassword(),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _submitting ? null : _submitNewPassword,
          child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text('ĐỔI MẬT KHẨU'),
        ),
      ],
    );
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
                  Text(
                    _step == 0 ? 'Quên mật khẩu' : _step == 1 ? 'Xác thực OTP' : 'Đặt lại mật khẩu',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBrown),
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
                  if (_step == 0) _buildEmailStep(),
                  if (_step == 1) _buildOtpStep(),
                  if (_step == 2) _buildPasswordStep(),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Quay lại Đăng nhập'),
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
