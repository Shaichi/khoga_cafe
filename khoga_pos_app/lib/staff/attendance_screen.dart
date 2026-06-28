import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/staff_api.dart';
import '../theme.dart';

/// Screen 31 — attendance terminal (UC-67). Any branch staff enters their PIN and
/// checks in or out; the result pairing is shown.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late final AttendanceApi _api;
  final _pin = TextEditingController();
  bool _busy = false;
  String? _error;
  Attendance? _result;

  @override
  void initState() {
    super.initState();
    _api = AttendanceApi(context.read<ApiClient>());
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _run(Future<Attendance> Function() action) async {
    if (_pin.text.trim().isEmpty) {
      setState(() => _error = 'Vui lòng nhập mã PIN');
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
      _result = null;
    });
    try {
      final res = await action();
      if (mounted) setState(() => _result = res);
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Thao tác thất bại');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrown,
        foregroundColor: Colors.white,
        title: const Text('Chấm công'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.badge_outlined, size: 56, color: kBrown),
                const SizedBox(height: 16),
                const Text('Nhập mã PIN nhân viên', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrown)),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  Text(_error!, key: const Key('attendance-error'),
                      textAlign: TextAlign.center, style: const TextStyle(color: kDanger)),
                  const SizedBox(height: 12),
                ],
                TextField(
                  key: const Key('attendance-pin'),
                  controller: _pin,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(hintText: '••••', counterText: ''),
                  style: const TextStyle(fontSize: 24, letterSpacing: 8),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        key: const Key('check-in-button'),
                        onPressed: _busy ? null : () => _run(() => _api.checkIn(_pin.text.trim())),
                        icon: const Icon(Icons.login),
                        label: const Text('VÀO CA'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('check-out-button'),
                        onPressed: _busy ? null : () => _run(() => _api.checkOut(_pin.text.trim())),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                        icon: const Icon(Icons.logout),
                        label: const Text('TAN CA'),
                      ),
                    ),
                  ],
                ),
                if (r != null) ...[
                  const SizedBox(height: 24),
                  _resultCard(r),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultCard(Attendance r) {
    final checkedOut = r.checkOutAt != null;
    return Container(
      key: const Key('attendance-result'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F7EF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB7E1C7)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: kSuccess, size: 40),
          const SizedBox(height: 8),
          Text(r.employeeName, style: const TextStyle(fontWeight: FontWeight.bold, color: kBrown, fontSize: 16)),
          const SizedBox(height: 4),
          Text(checkedOut ? 'Đã tan ca lúc ${_time(r.checkOutAt)}' : 'Đã vào ca lúc ${_time(r.checkInAt)}',
              style: const TextStyle(color: kBrown)),
          if (r.pendingVerification) ...[
            const SizedBox(height: 6),
            const Text('Chờ quản lý xác nhận (thiếu ảnh)', style: TextStyle(color: kDanger, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  String _time(String? iso) {
    if (iso == null) return '';
    final t = iso.contains('T') ? iso.split('T')[1] : iso;
    return t.length >= 5 ? t.substring(0, 5) : t;
  }
}
