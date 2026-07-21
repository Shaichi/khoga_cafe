import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/stock_api.dart';
import '../format.dart';
import '../theme.dart';

class StockAuditScreen extends StatefulWidget {
  final StockItem? initialItem;
  
  const StockAuditScreen({super.key, this.initialItem});

  @override
  State<StockAuditScreen> createState() => _StockAuditScreenState();
}

class _StockAuditScreenState extends State<StockAuditScreen> {
  late final StockApi _api;
  final _counts = <String, TextEditingController>{};
  final _notes = <String, TextEditingController>{};
  final _search = TextEditingController();
  
  List<StockItem> _allItems = const [];
  List<StockItem> _filteredItems = const [];
  
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<StockAuditResult>? _results;

  @override
  void initState() {
    super.initState();
    _api = StockApi(context.read<ApiClient>());
    _search.addListener(_filter);
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    for (final c in _counts.values) {
      c.dispose();
    }
    for (final c in _notes.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _filter() {
    final query = _search.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _allItems;
      } else {
        _filteredItems = _allItems.where((i) {
          return i.name.toLowerCase().contains(query) || i.code.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.initialItem != null) {
        final list = [widget.initialItem!];
        if (mounted) {
          setState(() {
            _allItems = list;
            _filteredItems = list;
            _counts.putIfAbsent(list.first.id, () => TextEditingController());
            _notes.putIfAbsent(list.first.id, () => TextEditingController());
          });
        }
      } else {
        final list = await _api.list();
        if (mounted) {
          setState(() {
            _allItems = list;
            _filteredItems = list;
            for (final s in list) {
              _counts.putIfAbsent(s.id, () => TextEditingController());
              _notes.putIfAbsent(s.id, () => TextEditingController());
            }
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Không tải được kho');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final lines = <Map<String, dynamic>>[];
    for (final s in _allItems) {
      final raw = _counts[s.id]?.text.trim() ?? '';
      if (raw.isEmpty) continue; // un-counted items are skipped
      final qty = num.tryParse(raw);
      if (qty == null || qty < 0) {
        setState(() => _error = 'Số lượng không hợp lệ cho ${s.name}');
        return;
      }
      
      final note = _notes[s.id]?.text.trim() ?? '';
      if (qty != s.currentQuantity && note.isEmpty) {
        setState(() => _error = 'Vui lòng nhập lý do chênh lệch cho ${s.name}');
        return;
      }

      final payload = <String, dynamic>{
        'stockItemId': s.id,
        'actualQuantity': qty,
      };
      if (note.isNotEmpty) {
        payload['note'] = note;
      }
      lines.add(payload);
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
    final isSingleAudit = widget.initialItem != null;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrown,
        foregroundColor: Colors.white,
        title: Text(isSingleAudit ? 'Kiểm kê vật lý' : 'Kiểm kê toàn bộ'),
      ),
      body: SafeArea(
        child: results != null ? _report(results) : _form(isSingleAudit),
      ),
    );
  }

  Widget _form(bool isSingleAudit) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && _allItems.isEmpty) {
      return Center(child: Text(_error!, style: const TextStyle(color: kDanger)));
    }
    return Column(
      children: [
        if (!isSingleAudit) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Tìm nhanh nguyên liệu...',
                prefixIcon: const Icon(Icons.search, color: kMuted),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kBrown),
                ),
              ),
            ),
          ),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kDanger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kDanger),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: kDanger),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_error!, key: const Key('audit-error'), style: const TextStyle(color: kDanger, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
          ),
        Expanded(
          child: _filteredItems.isEmpty
              ? const Center(child: Text('Không tìm thấy nguyên liệu', style: TextStyle(color: kMuted)))
              : ListView.separated(
                  key: const Key('audit-list'),
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredItems.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final item = _filteredItems[i];
                    return _AuditCountRow(
                      item: item,
                      countController: _counts[item.id]!,
                      noteController: _notes[item.id]!,
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: kBorder)),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              key: const Key('audit-submit'),
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrown,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _submitting
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('HOÀN TẤT KIỂM KÊ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _report(List<StockAuditResult> results) => Column(
        key: const Key('audit-report'),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            color: Colors.white,
            child: Column(
              children: [
                const Icon(Icons.fact_check, color: kSuccess, size: 48),
                const SizedBox(height: 12),
                const Text('Báo Cáo Kiểm Kê', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBrownDark)),
                const SizedBox(height: 4),
                Text('Đã kiểm kê ${results.length} mặt hàng', style: const TextStyle(color: kMuted)),
              ],
            ),
          ),
          const Divider(height: 1, color: kBorder),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: results.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _reportRow(results[i]),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: kBorder)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                key: const Key('audit-done'),
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrown,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('XONG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      );

  Widget _reportRow(StockAuditResult r) {
    final adj = r.adjustment;
    final matched = adj == 0;
    
    // Highlight discrepancies
    final color = matched ? kMuted : (adj > 0 ? kSuccess : kDanger);
    final sign = adj > 0 ? '+' : '';
    final bgColor = matched ? Colors.white : color.withValues(alpha: 0.05);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: matched ? kBorder : color.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        key: Key('audit-result-${r.stockItemId}'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(r.name, style: TextStyle(fontWeight: FontWeight.bold, color: matched ? kBrownDark : color)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('Sổ sách: ${formatVnd(r.systemQuantity)} → Thực đếm: ${formatVnd(r.actualQuantity)}',
              style: TextStyle(color: matched ? kMuted : kBrownDark, fontSize: 13)),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: matched ? kBorder : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            matched ? 'Khớp' : '$sign${formatVnd(adj)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: matched ? kBrownDark : color, fontSize: 14),
          ),
        ),
      ),
    );
  }
}

class _AuditCountRow extends StatefulWidget {
  final StockItem item;
  final TextEditingController countController;
  final TextEditingController noteController;

  const _AuditCountRow({
    required this.item,
    required this.countController,
    required this.noteController,
  });

  @override
  State<_AuditCountRow> createState() => _AuditCountRowState();
}

class _AuditCountRowState extends State<_AuditCountRow> {
  bool _hasDiscrepancy = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.countController.addListener(_checkDiscrepancy);
    _focusNode.addListener(_onFocusChange);
    _checkDiscrepancy(); // Check initial state
  }

  @override
  void dispose() {
    widget.countController.removeListener(_checkDiscrepancy);
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {});
  }

  void _checkDiscrepancy() {
    final raw = widget.countController.text.trim();
    if (raw.isEmpty) {
      if (_hasDiscrepancy) setState(() => _hasDiscrepancy = false);
      return;
    }
    
    final qty = num.tryParse(raw);
    if (qty == null) return;
    
    final isDifferent = qty != widget.item.currentQuantity;
    if (_hasDiscrepancy != isDifferent) {
      setState(() {
        _hasDiscrepancy = isDifferent;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.item;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _hasDiscrepancy ? kDanger.withValues(alpha: 0.5) : kBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kBrownDark)),
                    const SizedBox(height: 4),
                    Text('Hệ thống: ${formatVnd(s.currentQuantity)} ${s.unit}',
                        style: const TextStyle(color: kMuted, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 140, // Increased width to prevent hint text truncation
                child: TextField(
                  key: Key('audit-count-${s.id}'),
                  controller: widget.countController,
                  focusNode: _focusNode,
                  textAlign: TextAlign.right,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  decoration: InputDecoration(
                    suffixText: s.unit, 
                    isDense: true,
                    hintText: _focusNode.hasFocus ? null : 'Thực đếm',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          
          if (_hasDiscrepancy) ...[
            const SizedBox(height: 12),
            TextField(
              key: Key('audit-note-${s.id}'),
              controller: widget.noteController,
              decoration: InputDecoration(
                hintText: 'Nhập lý do chênh lệch (Bắt buộc)...',
                hintStyle: const TextStyle(fontSize: 13),
                filled: true,
                fillColor: kDanger.withValues(alpha: 0.05),
                isDense: true,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: kDanger.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: kDanger.withValues(alpha: 0.3)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
