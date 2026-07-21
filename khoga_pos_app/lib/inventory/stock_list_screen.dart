import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/stock_api.dart';
import '../format.dart';
import '../theme.dart';
import 'export_stock_screen.dart';
import 'import_stock_screen.dart';
import 'stock_audit_screen.dart';
import 'stock_transactions_screen.dart';

class StockListScreen extends StatefulWidget {
  final bool initialLowOnly;
  const StockListScreen({super.key, this.initialLowOnly = false});

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
    _lowOnly = widget.initialLowOnly;
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

  void _showNotImplemented() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng đang phát triển')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: kBrownDark,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 120,
        leading: TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: kMuted, size: 20),
          label: const Text(
            'Quay lại',
            style: TextStyle(
              color: kMuted,
              fontFamily: 'Segoe UI',
              fontSize: 16,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.only(left: 16),
            alignment: Alignment.centerLeft,
          ),
        ),
        title: const Text(
          'Kho Nguyên Liệu',
          style: TextStyle(
            fontFamily: 'Segoe UI',
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              key: const Key('stock-ledger-action'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const StockTransactionsScreen()),
              ),
              child: const Text(
                'Lịch sử',
                style: TextStyle(
                  fontFamily: 'Segoe UI',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFFC89D7C),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final refreshed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute<bool>(builder: (_) => const ImportStockScreen()),
                        );
                        if (refreshed == true) _load();
                      },
                      icon: const Icon(Icons.add, color: kBrown, size: 20),
                      label: const Text(
                        'Nhập Kho',
                        style: TextStyle(color: kBrown, fontWeight: FontWeight.bold, fontFamily: 'Segoe UI'),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: kBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final refreshed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute<bool>(builder: (_) => const ExportStockScreen()),
                        );
                        if (refreshed == true) _load();
                      },
                      icon: const Icon(Icons.remove, color: kBrown, size: 20),
                      label: const Text(
                        'Xuất Kho',
                        style: TextStyle(color: kBrown, fontWeight: FontWeight.bold, fontFamily: 'Segoe UI'),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: kBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Search Input
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                key: const Key('stock-search'),
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm nguyên liệu...',
                  hintStyle: const TextStyle(fontFamily: 'Segoe UI', color: kMuted, fontSize: 15),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
                onSubmitted: (_) => _load(),
              ),
            ),
            
            // Low Stock Checkbox
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _lowOnly,
                      activeColor: Colors.blue,
                      onChanged: (v) {
                        setState(() => _lowOnly = v ?? false);
                        _load();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Chỉ hiện nguyên liệu sắp hết kho',
                    style: TextStyle(
                      fontFamily: 'Segoe UI',
                      color: kBrownDark,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(child: _list()),
          ],
        ),
      ),
      bottomNavigationBar: _buildFooter(),
    );
  }

  Widget _list() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: kDanger)));
    if (_items.isEmpty) return const Center(child: Text('Không có nguyên liệu', style: TextStyle(color: kMuted)));
    
    return ListView.separated(
      key: const Key('stock-list'),
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _row(_items[i]),
    );
  }

  Widget _row(StockItem s) {
    final statusColor = s.lowStock ? const Color(0xFFC66270) : const Color(0xFF2E7D32);
    final statusText = s.lowStock ? 'Hết hàng / Sắp hết' : 'Đầy đủ';
    final statusBg = s.lowStock ? const Color(0xFFFDE8EB) : const Color(0xFFE8F5E9);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: const TextStyle(
                          fontFamily: 'Segoe UI',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: kBrownDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mã: ${s.code}',
                        style: const TextStyle(
                          fontFamily: 'Segoe UI',
                          color: kMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontFamily: 'Segoe UI',
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${s.currentQuantity} ${s.unit}',
                      style: const TextStyle(
                        fontFamily: 'Segoe UI',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: kBrownDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tối thiểu: ${s.minAlertThreshold} ${s.unit}',
                      style: const TextStyle(
                        fontFamily: 'Segoe UI',
                        color: kMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: kBorder),
          InkWell(
            onTap: () async {
              final refreshed = await Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(builder: (_) => StockAuditScreen(initialItem: s)),
              );
              if (refreshed == true) _load();
            },
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              alignment: Alignment.centerRight,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fact_check_outlined, size: 18, color: Color(0xFFC89D7C)),
                  SizedBox(width: 6),
                  Text(
                    'Kiểm kê vật lý',
                    style: TextStyle(
                      fontFamily: 'Segoe UI',
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC89D7C),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: kBorder)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: kBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Trang chủ',
                  style: TextStyle(
                    fontFamily: 'Segoe UI',
                    color: kBrownDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                key: const Key('stock-audit-action'),
                onPressed: () async {
                  final refreshed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(builder: (_) => const StockAuditScreen()),
                  );
                  if (refreshed == true) _load();
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  minimumSize: const Size(0, 50),
                  backgroundColor: kBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Kiểm Kê Toàn Bộ',
                  style: TextStyle(
                    fontFamily: 'Segoe UI',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
