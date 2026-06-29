import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/stock_api.dart';
import '../format.dart';
import '../theme.dart';

/// Screen 28 (export) — withdraw/waste stock (UC-33). Reason is mandatory. Pops
/// with `true` on success so the dashboard refreshes.
class ExportStockScreen extends StatefulWidget {
  final StockItem item;
  const ExportStockScreen({super.key, required this.item});

  @override
  State<ExportStockScreen> createState() => _ExportStockScreenState();
}

class _ExportStockScreenState extends State<ExportStockScreen> {
  late final StockApi _api;
  final _qty = TextEditingController();
  final _reason = TextEditingController();
  bool _submitting = false;
  String? _error;
  StockTransaction? _result;

  @override
  void initState() {
    super.initState();
    _api = StockApi(context.read<ApiClient>());
  }

  @override
  void dispose() {
    _qty.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final qty = num.tryParse(_qty.text.trim());
    if (qty == null || qty <= 0) {
      setState(() => _error = 'Vui lòng nhập số lượng hợp lệ');
      return;
    }
    if (_reason.text.trim().isEmpty) {
      setState(() => _error = 'Vui lòng nhập lý do xuất kho');
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      final tx = await _api.export(widget.item.id, qty, _reason.text.trim());
      if (mounted) setState(() => _result = tx);
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Xuất kho thất bại');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final result = _result;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrown,
        foregroundColor: Colors.white,
        title: const Text('Xuất kho'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: result != null
              ? _success(result)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBrown)),
                    Text('${item.code} · tồn hiện tại ${formatVnd(item.currentQuantity)} ${item.unit}',
                        style: const TextStyle(color: kMuted, fontSize: 13)),
                    const SizedBox(height: 24),
                    if (_error != null) ...[
                      Text(_error!, key: const Key('export-error'), style: const TextStyle(color: kDanger)),
                      const SizedBox(height: 12),
                    ],
                    Text('Số lượng xuất (${item.unit}) *',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBrown)),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('export-quantity'),
                      controller: _qty,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    ),
                    const SizedBox(height: 16),
                    const Text('Lý do *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBrown)),
                    const SizedBox(height: 8),
                    TextField(key: const Key('export-reason'), controller: _reason, decoration: const InputDecoration(hintText: 'Hỏng / hết hạn…')),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      key: const Key('export-submit'),
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('XÁC NHẬN XUẤT KHO'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _success(StockTransaction tx) => Column(
        key: const Key('export-success'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: kSuccess, size: 64),
          const SizedBox(height: 12),
          const Text('Xuất kho thành công', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBrown)),
          const SizedBox(height: 8),
          Text('${tx.materialName}: ${formatVnd(tx.quantityBefore)} → ${formatVnd(tx.quantityAfter)}',
              style: const TextStyle(color: kMuted)),
          const SizedBox(height: 24),
          ElevatedButton(
            key: const Key('export-done'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('XONG'),
          ),
        ],
      );
}
