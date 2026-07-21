import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/stock_api.dart';
import '../format.dart';
import '../theme.dart';

/// Screen 26a — stock movement ledger (UC-61). History Log based on Figma design.
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
    ('RECIPE_DEDUCTION', 'Bán hàng'),
    ('AUDIT_ADJUSTMENT', 'Kiểm kê'),
  ];

  late final StockApi _api;
  String? _type;
  DateTimeRange? _dateRange;
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
      final list = await _api.transactions(
        type: _type,
        from: _dateRange?.start,
        to: _dateRange?.end != null ? _dateRange!.end.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)) : null,
      );
      if (mounted) setState(() => _items = list);
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Không tải được lịch sử kho');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, List<StockTransaction>> _groupTransactions() {
    final map = <String, List<StockTransaction>>{};
    for (final t in _items) {
      if (t.createdAt == null) continue;
      try {
        final dt = DateTime.parse(t.createdAt!).toLocal();
        final dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
        map.putIfAbsent(dateStr, () => []).add(t);
      } catch (_) {}
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: kBrownDark,
        elevation: 1,
        title: const Text('Lịch sử kho', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_dateRange == null ? Icons.calendar_month_outlined : Icons.calendar_month, color: kBrown),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
                initialDateRange: _dateRange,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: kBrown,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: kBrownDark,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() => _dateRange = picked);
                _load();
              }
            },
          ),
          if (_dateRange != null)
            IconButton(
              icon: const Icon(Icons.clear, color: kDanger),
              onPressed: () {
                setState(() => _dateRange = null);
                _load();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  for (final f in _filters)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f.$2, style: TextStyle(
                          color: _type == f.$1 ? Colors.white : kBrownDark,
                          fontWeight: _type == f.$1 ? FontWeight.bold : FontWeight.normal,
                        )),
                        selected: _type == f.$1,
                        selectedColor: kBrown,
                        backgroundColor: kBg,
                        onSelected: (_) {
                          setState(() => _type = f.$1);
                          _load();
                        },
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: kBorder),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: kDanger)));
    if (_items.isEmpty) return const Center(child: Text('Chưa có giao dịch nào', style: TextStyle(color: kMuted, fontSize: 16)));
    
    final grouped = _groupTransactions();
    final dates = grouped.keys.toList(); // Assuming already sorted descending by API

    return ListView.builder(
      key: const Key('tx-list'),
      padding: const EdgeInsets.all(16),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final dateStr = dates[index];
        final dayItems = grouped[dateStr]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 8),
              child: Text(
                dateStr,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kBrownDark),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
              ),
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: dayItems.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: kBorder),
                itemBuilder: (_, i) => _buildTransactionRow(dayItems[i]),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildTransactionRow(StockTransaction t) {
    final inbound = t.quantity >= 0;
    
    // Parse time
    String timeStr = '';
    if (t.createdAt != null) {
      try {
        final dt = DateTime.parse(t.createdAt!).toLocal();
        timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    // Config style based on type
    IconData icon;
    Color iconColor;
    switch (t.transactionType) {
      case 'IMPORT':
        icon = Icons.download_rounded;
        iconColor = kSuccess;
        break;
      case 'EXPORT':
        icon = Icons.upload_rounded;
        iconColor = kDanger;
        break;
      case 'AUDIT_ADJUSTMENT':
        icon = Icons.fact_check_rounded;
        iconColor = Colors.orange;
        break;
      case 'RECIPE_DEDUCTION':
        icon = Icons.local_cafe_rounded;
        iconColor = Colors.blueGrey;
        break;
      default:
        icon = Icons.swap_horiz_rounded;
        iconColor = kMuted;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        t.materialName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kBrownDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${inbound ? '+' : ''}${formatVnd(t.quantity)}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: inbound ? kSuccess : kDanger, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(timeStr, style: const TextStyle(color: kMuted, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: kBg,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: kBorder),
                      ),
                      child: Text(_typeLabel(t.transactionType), style: const TextStyle(fontSize: 11, color: kBrown)),
                    ),
                    if (t.managerName != null) ...[
                      const Text(' · ', style: TextStyle(color: kMuted)),
                      Text(t.managerName!, style: const TextStyle(fontSize: 12, color: kMuted)),
                    ],
                  ],
                ),
                if (t.reason != null && t.reason!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Ghi chú: ${t.reason}', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: kBrown)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(String t) => switch (t) {
        'IMPORT' => 'Nhập kho',
        'EXPORT' => 'Xuất kho',
        'RECIPE_DEDUCTION' => 'Bán hàng',
        'AUDIT_ADJUSTMENT' => 'Kiểm kê',
        'PHANTOM_USAGE' => 'Hao hụt',
        _ => t,
      };
}
