import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/stock_api.dart';
import '../format.dart';
import '../theme.dart';
import 'import_stock_screen.dart';
import 'stock_audit_screen.dart';
import 'stock_transactions_screen.dart';

/// Screen 26 — branch stock dashboard (UC-31). Search + low-stock filter; tapping
/// a row opens the import screen (32). The ledger (29) is one tap away.
class StockListScreen extends StatefulWidget {
  const StockListScreen({super.key});

  @override
  State<StockListScreen> createState() => _StockListScreenState();
}

class _StockListScreenState extends State<StockListScreen> {
  late final StockApi _api;
  final _search = TextEditingController();
  bool _lowOnly = false;
  List<StockItem> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = StockApi(context.read<ApiClient>());
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.list(lowStock: _lowOnly ? true : null, search: _search.text.trim());
      if (mounted) setState(() => _items = list);
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Không tải được kho');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrown,
        foregroundColor: Colors.white,
        title: const Text('Kho chi nhánh'),
        actions: [
          IconButton(
            key: const Key('stock-audit-action'),
            tooltip: 'Kiểm kê kho',
            icon: const Icon(Icons.fact_check_outlined),
            onPressed: () async {
              final refreshed = await Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(builder: (_) => const StockAuditScreen()),
              );
              if (refreshed == true) _load();
            },
          ),
          IconButton(
            key: const Key('stock-ledger-action'),
            tooltip: 'Lịch sử kho',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const StockTransactionsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                key: const Key('stock-search'),
                controller: _search,
                decoration: const InputDecoration(hintText: 'Tìm nguyên liệu…', prefixIcon: Icon(Icons.search)),
                onSubmitted: (_) => _load(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  FilterChip(
                    key: const Key('low-stock-filter'),
                    label: const Text('Sắp hết'),
                    selected: _lowOnly,
                    onSelected: (v) {
                      setState(() => _lowOnly = v);
                      _load();
                    },
                  ),
                ],
              ),
            ),
            Expanded(child: _list()),
          ],
        ),
      ),
    );
  }

  Widget _list() {
    if (_loading) return const Center(child: Text('Đang tải…'));
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: kDanger)));
    if (_items.isEmpty) return const Center(child: Text('Không có nguyên liệu', style: TextStyle(color: kMuted)));
    return ListView.separated(
      key: const Key('stock-list'),
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _row(_items[i]),
    );
  }

  Widget _row(StockItem s) => Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          key: Key('stock-row-${s.id}'),
          leading: Icon(Icons.inventory_2_outlined, color: s.lowStock ? kDanger : kBrown),
          title: Row(
            children: [
              Expanded(child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600))),
              if (s.lowStock)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: kDanger.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: const Text('Sắp hết', style: TextStyle(color: kDanger, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          subtitle: Text('${s.code} · ngưỡng ${formatVnd(s.minAlertThreshold)} ${s.unit}'),
          trailing: Text('${formatVnd(s.currentQuantity)} ${s.unit}',
              style: TextStyle(fontWeight: FontWeight.bold, color: s.lowStock ? kDanger : kBrown)),
          onTap: () async {
            final refreshed = await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(builder: (_) => ImportStockScreen(item: s)),
            );
            if (refreshed == true) _load();
          },
        ),
      );
}
