import 'package:flutter/material.dart';

import '../theme.dart';

class BranchSettingsScreen extends StatefulWidget {
  const BranchSettingsScreen({super.key});

  @override
  State<BranchSettingsScreen> createState() => _BranchSettingsScreenState();
}

class _BranchSettingsScreenState extends State<BranchSettingsScreen> {
  final _ipController = TextEditingController(text: '192.168.1.100');
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isTesting = false;

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() => _isConnecting = true);
    // Simulate connection delay
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isConnecting = false;
        _isConnected = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã kết nối thành công với máy in!')),
      );
    }
  }

  Future<void> _testPrint() async {
    setState(() => _isTesting = true);
    // Simulate print delay
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isTesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi lệnh in thử tới máy in!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: kBrownDark,
        elevation: 0,
        title: const Text(
          'Cấu hình chi nhánh',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 8),
              child: Text(
                'MÁY IN HOÁ ĐƠN (POS)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: kMuted,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.print_outlined, color: kBrown),
                      const SizedBox(width: 8),
                      const Text(
                        'Kết nối mạng LAN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kBrownDark,
                        ),
                      ),
                      const Spacer(),
                      if (_isConnected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: kSuccess.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Đã kết nối',
                            style: TextStyle(
                              color: kSuccess,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: kDanger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Chưa kết nối',
                            style: TextStyle(
                              color: kDanger,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Địa chỉ IP máy in', style: TextStyle(color: kBrownDark, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ipController,
                    decoration: InputDecoration(
                      hintText: '192.168.1.100',
                      filled: true,
                      fillColor: kBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.wifi, color: kMuted),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (val) {
                      if (_isConnected) setState(() => _isConnected = false);
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isConnected && !_isTesting ? _testPrint : null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: kBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isTesting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: kBrownDark),
                                )
                              : const Text(
                                  'In Thử',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: kBrownDark,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isConnecting ? null : _connect,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kBrown,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isConnecting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Kết Nối',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
