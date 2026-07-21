import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../auth/auth_controller.dart';
import '../theme.dart';
import 'change_password_screen.dart';

/// Screen 06/07 — self-service profile (UC-07 view, UC-08 edit). Identity fields
/// are read-only; email + phone are editable. Links to change-password (08).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _email;
  late final TextEditingController _phone;
  bool _saving = false;
  String? _error;
  bool _saved = false;

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
    setState(() {
      _error = null;
      _saving = true;
      _saved = false;
    });
    try {
      await context.read<AuthController>().updateProfile(email: _email.text.trim(), phone: _phone.text.trim());
      if (mounted) setState(() => _saved = true);
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
    final p = context.watch<AuthController>().profile;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrown,
        foregroundColor: Colors.white,
        title: const Text('Hồ sơ của tôi'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CircleAvatar(radius: 36, backgroundColor: kGold, child: Icon(Icons.person, size: 40, color: Colors.white)),
                const SizedBox(height: 12),
                Text(p?.fullName ?? '', key: const Key('profile-name'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBrown)),
                Text('${p?.username ?? ''} · ${p?.role ?? ''}',
                    textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  Text(_error!, key: const Key('profile-error'), style: const TextStyle(color: kDanger)),
                  const SizedBox(height: 12),
                ],
                if (_saved) ...[
                  const Text('Đã lưu hồ sơ', key: Key('profile-saved'), style: TextStyle(color: kSuccess)),
                  const SizedBox(height: 12),
                ],
                const Text('Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBrown)),
                const SizedBox(height: 8),
                TextField(key: const Key('profile-email'), controller: _email, keyboardType: TextInputType.emailAddress, inputFormatters: [LengthLimitingTextInputFormatter(100)]),
                const SizedBox(height: 16),
                const Text('Số điện thoại', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBrown)),
                const SizedBox(height: 8),
                TextField(key: const Key('profile-phone'), controller: _phone, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(20)]),
                const SizedBox(height: 24),
                ElevatedButton(
                  key: const Key('profile-save'),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('LƯU THAY ĐỔI'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const Key('change-password-action'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const ChangePasswordScreen()),
                  ),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('ĐỔI MẬT KHẨU'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
