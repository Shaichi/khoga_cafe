import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/stock_api.dart';
import '../format.dart';
import '../theme.dart';

/// Screen 28 (audit) — physical stock count (UC-34). The manager keys the
/// actual on-hand quantity for each material; submitting returns the per-item
/// discrepancy report (system vs actual + the adjustment Hibernate applied).
/// Pops with `true` on success so the dashboard refreshes.
class StockAuditScreen extends StatefulWidget {
  const StockAuditScreen({super.key});

  @override
  State<StockAuditScreen> createState() => _StockAuditScreenState();
}

class _StockAuditScreenState extends State<StockAuditScreen> {
  late final StockApi _api;
  final _counts = <String, TextEditingController>{};
  List<StockItem> _items = const [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<StockAuditResult>? _results;

  @override
  void initState() {
    super.initState();
    _api = StockApi(context.read<ApiClient>());
    _load();
  }

  @override
  void dispose() {
    for (final c in _counts.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.list();
      if (mounted) {
        setState(() {
          _items = list;
          for (final s in list) {
            _counts.putIfAbsent(s.id, () => TextEditingController());
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Không tải được kho');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final lines = <Map<String, dynamic>>[];
    for (final s in _items) {
      final raw = _counts[s.id]?.text.trim() ?? '';
      if (raw.isEmpty) continue; // un-counted items are skipped
      final qty = num.tryParse(raw);
      if (qty == null || qty < 0) {
        setState(() => _error = 'Số lượng không hợp lệ cho ${s.name}');
        return;
      }
      lines.add({'stockItemId': s.id, 'actualQuantity': qty});
    }
    if (lines.isEmpty) {
      setState(() => _error = 'Vui lòng nhập ít nhất một số lượng kiểm kê');
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      final results = await _api.audit(lines);
      if (mounted) setState(() => _results = results);
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Kiểm kê thất bại');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrown,
        foregroundColor: Colors.white,
        title: const Text('Kiểm kê kho'),
      ),
      body: SafeArea(
        child: results != null ? _report(results) : _form(),
      ),
    );
  }

  Widget _form() {
    if (_loading) return const Center(child: Text('Đang tải…'));
    if (_error != null && _items.isEmpty) {
      return Center(child: Text(_error!, style: const TextStyle(color: kDanger)));
    }
    return Column(
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(_error!, key: const Key('audit-error'), style: const TextStyle(color: kDanger)),
          ),
        Expanded(
          child: ListView.separated(
            key: const Key('audit-list'),
            padding: const EdgeInsets.all(16),
            itemCount: _items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _countRow(_items[i]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('audit-submit'),
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('HOÀN TẤT KIỂM KÊ'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _countRow(StockItem s) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('Hệ thống: ${formatVnd(s.currentQuantity)} ${s.unit}',
                        style: const TextStyle(color: kMuted, fontSize: 12)),
                  ],
                ),
              ),
              SizedBox(
                width: 96,
                child: TextField(
                  key: Key('audit-count-${s.id}'),
                  controller: _counts[s.id],
                  textAlign: TextAlign.right,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  decoration: InputDecoration(suffixText: s.unit, isDense: true),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _report(List<StockAuditResult> results) => Column(
        key: const Key('audit-report'),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Icon(Icons.fact_check, color: kSuccess),
                SizedBox(width: 8),
                Text('Kiểm kê hoàn tất', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBrown)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: results.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _reportRow(results[i]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('audit-done'),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('XONG'),
              ),
            ),
          ),
        ],
      );

  Widget _reportRow(StockAuditResult r) {
    final adj = r.adjustment;
    final matched = adj == 0;
    final color = matched ? kSuccess : kDanger;
    final sign = adj > 0 ? '+' : '';
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        key: Key('audit-result-${r.stockItemId}'),
        title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${formatVnd(r.systemQuantity)} → ${formatVnd(r.actualQuantity)}',
            style: const TextStyle(color: kMuted)),
        trailing: Text(
          matched ? 'Khớp' : '$sign${formatVnd(adj)}',
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
}
