import 'package:flutter/material.dart';
import '../theme.dart';

Future<bool?> showLogoutDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFFFCF9F5),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(false),
                  child: const Text('>', style: TextStyle(fontSize: 20, color: kBrown, fontWeight: FontWeight.w300)),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFF9F1EB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout, size: 32, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              const Text(
                'Đăng xuất tài khoản?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kBrown,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bạn có chắc chắn muốn đăng xuất khỏi cổng thông tin nhân sự Khoga Café không?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: kMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBrown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('ĐĂNG XUẤT', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kBrown,
                    side: const BorderSide(color: Color(0xFFE5D5C5)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('HỦY BỎ', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
