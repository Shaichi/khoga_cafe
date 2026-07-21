import 'package:flutter/material.dart';

class LogoutConfirmModal extends StatelessWidget {
  const LogoutConfirmModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFF2EDE8)),
      ),
      elevation: 0,
      child: Container(
        width: 325,
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 102,
                height: 102,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF8F4),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF5EDE6)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC89D7C).withOpacity(0.14),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.logout_rounded,
                    size: 48,
                    color: Color(0xFF2C1A11), // dark brown
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Title
            const Text(
              'Đăng xuất tài khoản?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Segoe UI',
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Color(0xFF2C1A11),
                height: 28 / 22,
              ),
            ),
            const SizedBox(height: 12),
            
            // Subtitle
            const Text(
              'Bạn có chắc chắn muốn đăng xuất khỏi cổng thông tin nhân sự Khoga Café không?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Segoe UI',
                fontWeight: FontWeight.normal,
                fontSize: 15,
                color: Color(0xFF8C766C),
                height: 24 / 15,
              ),
            ),
            const SizedBox(height: 32),
            
            // "ĐĂNG XUẤT" Button
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D2314),
                foregroundColor: Colors.white,
                elevation: 4, // Drop shadow matching Figma
                shadowColor: const Color(0xFF3D2314).withOpacity(0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                minimumSize: const Size.fromHeight(52),
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'ĐĂNG XUẤT',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // "HỦY BỎ" Button
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3D2314),
                side: const BorderSide(color: Color(0xFFEADDD3), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                minimumSize: const Size.fromHeight(52),
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'HỦY BỎ',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
