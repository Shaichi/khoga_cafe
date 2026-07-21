import 'package:flutter/material.dart';

class RefundOrderDialog extends StatefulWidget {
  final num amount;
  
  const RefundOrderDialog({super.key, required this.amount});

  @override
  State<RefundOrderDialog> createState() => _RefundOrderDialogState();
}

class _RefundOrderDialogState extends State<RefundOrderDialog> {
  final _pinCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  String _type = 'REFUND';

  @override
  void dispose() {
    _pinCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hoàn tiền / Làm lại'),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Loại yêu cầu'),
              items: const [
                DropdownMenuItem(value: 'REFUND', child: Text('Hoàn tiền (Refund)')),
                DropdownMenuItem(value: 'COMP_REMAKE', child: Text('Làm lại miễn phí (Comp Remake)')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonCtrl,
              decoration: const InputDecoration(labelText: 'Lý do *', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pinCtrl,
              decoration: const InputDecoration(labelText: 'Mã PIN Quản lý (SM) *', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
        ElevatedButton(
          onPressed: () {
            final pin = _pinCtrl.text.trim();
            final reason = _reasonCtrl.text.trim();
            if (pin.isEmpty || reason.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đầy đủ lý do và mã PIN')));
              return;
            }
            Navigator.of(context).pop({
              'type': _type,
              'reason': reason,
              'smPin': pin,
            });
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
