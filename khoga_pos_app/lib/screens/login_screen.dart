import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../auth/auth_controller.dart';
import '../theme.dart';
import 'forgot_password_screen.dart';

/// Screen 01 — "Staff Portal" login. Submits credentials to AuthController; on
/// success the AuthGate swaps to the home screen.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      await context.read<AuthController>().login(_username.text.trim(), _password.text);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Không kết nối được máy chủ');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildLoginForm() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 327),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 60),
          const Text(
            'Khoga Café',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontFamily: 'Segoe UI',
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C1A11),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Staff Portal',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Segoe UI',
              fontWeight: FontWeight.bold,
              color: Color(0xFF8C766C),
            ),
          ),
          const SizedBox(height: 40),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDECEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF3C9C6)),
              ),
              child: Text(_error!, style: const TextStyle(color: kDanger, fontSize: 14)),
            ),
            const SizedBox(height: 16),
          ],
          const _FieldLabel('Tên đăng nhập'),
          SizedBox(
            height: 48,
            child: TextField(
              key: const Key('username'),
              controller: _username,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontFamily: 'Arial', fontSize: 16, color: Colors.black),
              inputFormatters: [LengthLimitingTextInputFormatter(50)],
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFFDFDFD),
                contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 0),
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
                  borderSide: const BorderSide(color: Color(0xFFC89D7C), width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _FieldLabel('Mật khẩu'),
          SizedBox(
            height: 48,
            child: TextField(
              key: const Key('password'),
              controller: _password,
              obscureText: true,
              style: const TextStyle(fontFamily: 'Arial', fontSize: 16, color: Colors.black),
              inputFormatters: [LengthLimitingTextInputFormatter(255)],
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFFDFDFD),
                contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 0),
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
                  borderSide: const BorderSide(color: Color(0xFFC89D7C), width: 2),
                ),
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            key: const Key('login-button'),
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3D2314),
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text(
                    'ĐĂNG NHẬP',
                    style: TextStyle(
                      fontFamily: 'Arial',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
            ),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFC89D7C),
              minimumSize: const Size.fromHeight(40),
            ),
            child: const Text(
              'Quên mật khẩu?',
              style: TextStyle(
                fontFamily: 'Segoe UI',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    if (isTablet) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Row(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                color: const Color(0xFF3D2314),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.coffee, size: 80, color: Colors.white),
                      SizedBox(height: 24),
                      Text(
                        'Khoga Café',
                        style: TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Segoe UI',
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'POS & Management System',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontFamily: 'Segoe UI',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 7,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 327, maxHeight: 600),
                  child: _buildLoginForm(),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: _buildLoginForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontFamily: 'Segoe UI',
            fontWeight: FontWeight.bold,
            color: Color(0xFF5C3826),
          ),
        ),
      );
}
