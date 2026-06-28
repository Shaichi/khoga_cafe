import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/stock_api.dart';
import '../format.dart';
import '../theme.dart';

/// Screen 29 — stock movement ledger (UC-61). Read-only history with a type filter.
class StockTransactionsScreen extends StatefulWidget {
  const StockTransactionsScreen({super.key});

  @override
  State<StockTransactionsScreen> createState() => _StockTransactionsScreenState();
}

class _StockTransactionsScreenState extends State<StockTransactionsScreen> {
  static const _filters = [
    (null, 'Tất cả'),
    ('IMPORT', 'Nhập'),
    ('EXPORT', 'Xuất'),
    ('RECIPE_DEDUCTION', 'Trừ công thức'),
    ('AUDIT_ADJUSTMENT', 'Kiểm kê'),
  ];

  late final StockApi _api;
  String? _type;
  List<StockTransaction> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = StockApi(context.read<ApiClient>());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.transactions(type: _type);
      if (mounted) setState(() => _items = list);
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Không tải được lịch sử kho');
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
        title: const Text('Lịch sử kho'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                children: [
                  for (final f in _filters)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f.$2),
                        selected: _type == f.$1,
                        onSelected: (_) {
                          setState(() => _type = f.$1);
                          _load();
                        },
                      ),
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
    if (_items.isEmpty) return const Center(child: Text('Chưa có giao dịch', style: TextStyle(color: kMuted)));
    return ListView.separated(
      key: const Key('tx-list'),
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final t = _items[i];
        final inbound = t.quantity >= 0;
        return ListTile(
          title: Text(t.materialName, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${_typeLabel(t.transactionType)}'
              '${t.managerName != null ? ' · ${t.managerName}' : ''}'),
          trailing: Text(
            '${inbound ? '+' : ''}${formatVnd(t.quantity)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: inbound ? kSuccess : kDanger),
          ),
        );
      },
    );
  }

  String _typeLabel(String t) => switch (t) {
        'IMPORT' => 'Nhập kho',
        'EXPORT' => 'Xuất kho',
        'RECIPE_DEDUCTION' => 'Trừ công thức',
        'AUDIT_ADJUSTMENT' => 'Điều chỉnh kiểm kê',
        'PHANTOM_USAGE' => 'Hao hụt',
        _ => t,
      };
}
