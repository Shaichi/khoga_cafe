import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import 'auth_controller.dart';

/// Screen — "Logout Confirmation" per Figma 227:79.
/// Dedicated full-screen confirmation page.
class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F6),
        foregroundColor: kBrownDark,
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
                    maxWidth: 400,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Top Content (Icon, Title, Subtitle) pushed to middle/top
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 20),
                                // Icon illustration
                                Container(
                                  width: 102,
                                  height: 102,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDF8F4),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFF5EDE6)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFC89D7C).withValues(alpha: 0.14),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.logout_rounded,
                                    size: 44,
                                    color: Color(0xFF3D2314),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                const Text(
                                  'Đăng xuất tài khoản?',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C1A11),
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Bạn có chắc chắn muốn đăng xuất khỏi cổng thông tin nhân sự Khoga Café không?',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 15,
                                    fontWeight: FontWeight.normal,
                                    color: Color(0xFF8C766C),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                          // Bottom Actions (Confirm & Cancel) anchored at the bottom
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    auth.logout();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3D2314),
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shadowColor: const Color(0xFF3D2314).withValues(alpha: 0.15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'ĐĂNG XUẤT',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF3D2314),
                                    side: const BorderSide(color: Color(0xFFEADDD3), width: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'HỦY BỎ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
}
