import 'package:flutter/material.dart';

import '../theme.dart';

class BranchSettingsScreen extends StatefulWidget {
  const BranchSettingsScreen({super.key});

  @override
  State<BranchSettingsScreen> createState() => _BranchSettingsScreenState();
}

class _BranchSettingsScreenState extends State<BranchSettingsScreen> {
  final _nameController = TextEditingController(text: 'Khoga Café - Nguyễn Du Branch');
  final _timezoneController = TextEditingController();
  final _hotlineController = TextEditingController(text: '0283930001');
  final _emailController = TextEditingController(text: 'nguyendu@khogacafe.vn');
  final _addressController = TextEditingController(text: '123 Nguyễn Du, Phường Bến Thành, Quận 1, TP. Hồ Chí Minh');


  @override
  void dispose() {
    _nameController.dispose();
    _timezoneController.dispose();
    _hotlineController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: kBrownDark,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: kBrownDark, fontSize: 15),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEBEBEB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEBEBEB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBrown),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        foregroundColor: kBrownDark,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Cấu Hình Chi Nhánh',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildLabel('Tên chi nhánh *'),
            _buildTextField(_nameController),

            _buildLabel('Múi giờ hoạt động *'),
            _buildTextField(_timezoneController),

            _buildLabel('Hotline liên hệ *'),
            _buildTextField(_hotlineController),

            _buildLabel('Địa chỉ Email *'),
            _buildTextField(_emailController),

            _buildLabel('Địa chỉ chi nhánh *'),
            _buildTextField(_addressController, maxLines: 2),

            // Bottom Actions (Now part of the scrolling list)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kBrownDark,
                      side: const BorderSide(color: Color(0xFFEAE2D8)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.white,
                    ),
                    child: const Text('HỦY', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã lưu cài đặt chi nhánh!')),
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3E2723), // Dark brown
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('LƯU CÀI ĐẶT', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
