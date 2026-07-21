import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../auth/auth_controller.dart';
import '../theme.dart';

/// Screen — "Chỉnh Sửa Thông Tin" per Figma Node 28:214.
/// Dedicated mobile/desktop page allowing users to update personal contact info.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _email;
  late final TextEditingController _phone;
  bool _saving = false;
  String? _error;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<AuthController>().profile;
    _email = TextEditingController(text: p?.email ?? '');
    _phone = TextEditingController(text: p?.phone ?? '');
  }

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_email.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      setState(() => _error = 'Vui lòng điền đầy đủ email và số điện thoại');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await context.read<AuthController>().updateProfile(
            email: _email.text.trim(),
            phone: _phone.text.trim(),
          );
      if (mounted) setState(() => _done = true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Không kết nối được máy chủ');
    } finally {
      if (mounted) setState(() => _saving = false);
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
          'Chỉnh Sửa Thông Tin',
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
          'Cập nhật thông tin liên hệ cá nhân của bạn.',
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

        // Field 1: Email liên hệ
        const Text(
          'Email liên hệ',
          style: TextStyle(
            fontFamily: 'Segoe UI',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5C3826),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Nhập email liên hệ',
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
          ),
        ),
        const SizedBox(height: 20),

        // Field 2: Số điện thoại
        const Text(
          'Số điện thoại',
          style: TextStyle(
            fontFamily: 'Segoe UI',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5C3826),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: 'Nhập số điện thoại',
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
          ),
        ),

        // Spacer to push actions to the bottom
        const Spacer(),
        const SizedBox(height: 40),

        // Primary Button: LƯU THAY ĐỔI
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3D2314),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'LƯU THAY ĐỔI',
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

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 30),
        const Icon(Icons.check_circle_rounded, color: kSuccess, size: 68),
        const SizedBox(height: 16),
        const Text(
          'Cập nhật thành công',
          style: TextStyle(
            fontFamily: 'Segoe UI',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C1A11),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Thông tin cá nhân của bạn đã được cập nhật.',
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
