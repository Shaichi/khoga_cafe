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
    } catch (e) {
      if (mounted) setState(() => _error = 'Lỗi gửi OTP: $e');
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
          style: ElevatedButton.styleFrom(
            backgroundColor: kBrown,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text('GỬI OTP', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Nhập mã xác thực gồm 6 chữ số đã được gửi tới\nemail của bạn.',
          textAlign: TextAlign.center,
          style: TextStyle(color: kMuted, height: 1.5, fontSize: 13),
        ),
        const SizedBox(height: 32),
        Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                final text = _otpCtrl.text;
                final char = text.length > index ? text[index] : '';
                final isFocused = text.length == index;
                return Container(
                  width: 45,
                  height: 55,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: isFocused ? kGold : const Color(0xFFE5E5E5),
                      width: isFocused ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    char,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBrown),
                  ),
                );
              }),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.0,
                child: TextField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) {
                    if (_otpCtrl.text.length == 6) _submitOtp();
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: _submitting ? null : _submitOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: kBrown,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text('XÁC NHẬN', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () {
              // Resend logic
            },
            child: const Text('Gửi lại mã xác thực', style: TextStyle(color: Color(0xFFD6A07B), fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Tạo mật khẩu bảo mật mới cho tài khoản.',
          textAlign: TextAlign.center,
          style: TextStyle(color: kMuted, height: 1.5, fontSize: 13),
        ),
        const SizedBox(height: 32),
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
          onSubmitted: (_) => _submitNewPassword(),
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
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF9F6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFF5E6DC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Độ phức tạp bắt buộc', style: TextStyle(color: kBrown, fontWeight: FontWeight.bold, fontSize: 12)),
              SizedBox(height: 8),
              Text(
                'Mật khẩu có độ dài ít nhất 8 ký tự, bao gồm chữ viết hoa, chữ viết thường, chữ số và ký tự đặc biệt.',
                style: TextStyle(color: kMuted, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: _submitting ? null : _submitNewPassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: kBrown,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text('LƯU MẬT KHẨU', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    _step == 0 ? 'Quên mật khẩu' : _step == 1 ? 'Xác Thực OTP' : 'Mật Khẩu Mới',
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
                  if (_step == 0)
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
