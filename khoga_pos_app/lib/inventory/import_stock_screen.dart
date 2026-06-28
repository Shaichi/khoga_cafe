import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/stock_api.dart';
import '../format.dart';
import '../theme.dart';

/// Screen 32 — record a stock delivery (UC-32) for one material. On success it
/// pops with `true` so the dashboard can refresh.
class ImportStockScreen extends StatefulWidget {
  final StockItem item;
  const ImportStockScreen({super.key, required this.item});

  @override
  State<ImportStockScreen> createState() => _ImportStockScreenState();
}

class _ImportStockScreenState extends State<ImportStockScreen> {
  late final StockApi _api;
  final _qty = TextEditingController();
  final _note = TextEditingController();
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
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final qty = num.tryParse(_qty.text.trim());
    if (qty == null || qty <= 0) {
      setState(() => _error = 'Vui lòng nhập số lượng hợp lệ');
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      final tx = await _api.import(widget.item.id, qty, note: _note.text.trim());
      if (mounted) setState(() => _result = tx);
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Nhập kho thất bại');
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
        title: const Text('Nhập kho'),
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
                      Text(_error!, key: const Key('import-error'), style: const TextStyle(color: kDanger)),
                      const SizedBox(height: 12),
                    ],
                    Text('Số lượng nhập (${item.unit}) *',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBrown)),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('import-quantity'),
                      controller: _qty,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    ),
                    const SizedBox(height: 16),
                    const Text('Ghi chú', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBrown)),
                    const SizedBox(height: 8),
                    TextField(key: const Key('import-note'), controller: _note),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      key: const Key('import-submit'),
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('XÁC NHẬN NHẬP KHO'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _success(StockTransaction tx) => Column(
        key: const Key('import-success'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: kSuccess, size: 64),
          const SizedBox(height: 12),
          const Text('Nhập kho thành công', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBrown)),
          const SizedBox(height: 8),
          Text('${tx.materialName}: ${formatVnd(tx.quantityBefore)} → ${formatVnd(tx.quantityAfter)}',
              style: const TextStyle(color: kMuted)),
          const SizedBox(height: 24),
          ElevatedButton(
            key: const Key('import-done'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('XONG'),
          ),
        ],
      );
}
