import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../auth/auth_controller.dart';
import '../theme.dart';
import 'shift_controller.dart';

/// Screen 34 — "Shift Initiation". The cashier picks a POS register and enters
/// the opening cash float before the POS unlocks (BR-33/92).
class OpenShiftScreen extends StatefulWidget {
  const OpenShiftScreen({super.key});

  @override
  State<OpenShiftScreen> createState() => _OpenShiftScreenState();
}

class _OpenShiftScreenState extends State<OpenShiftScreen> {
  final _register = TextEditingController();
  final _cash = TextEditingController(text: '1000000');
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _register.dispose();
    _cash.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final register = _register.text.trim();
    final cash = num.tryParse(_cash.text.trim());
    if (register.isEmpty) {
      setState(() => _error = 'Vui lòng nhập máy POS');
      return;
    }
    if (cash == null || cash < 0) {
      setState(() => _error = 'Tiền đầu ca không hợp lệ');
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      await context.read<ShiftController>().open(register, cash);
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
                  const Text('Khoga Café',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kBrown)),
                  const SizedBox(height: 4),
                  const Text('Cổng POS Thu Ngân',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: kMuted)),
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
                  const _Label('Chọn máy POS *'),
                  TextField(
                    key: const Key('register'),
                    controller: _register,
                    decoration: const InputDecoration(hintText: 'vd: POS-01'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  const _Label('Tiền mặt đầu ca (VND) *'),
                  TextField(
                    key: const Key('starting-cash'),
                    controller: _cash,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    key: const Key('open-shift-button'),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('BẮT ĐẦU CA LÀM'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.read<AuthController>().logout(),
                    child: const Text('Đăng xuất tài khoản', style: TextStyle(color: kGold, fontWeight: FontWeight.bold)),
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

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBrown)),
      );
}
