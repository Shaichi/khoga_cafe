import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/stock_api.dart';
import '../format.dart';

// Figma Colors
const Color cBgWhite = Color(0xFFFFFFFF);
const Color cBorderLight = Color(0xFFEADDD3);
const Color cTextDark = Color(0xFF2C1A11);
const Color cTextMuted = Color(0xFF8C766C);
const Color cBrownDark = Color(0xFF3D2314);
const Color cPrimary = Color(0xFF5C3826);

const Color cImportBg = Color(0xFFE8F5E9);
const Color cImportText = Color(0xFF2E7D32);
const Color cExportBg = Color(0xFFFFEBEE);
const Color cExportText = Color(0xFFC62828);
const Color cAuditBg = Color(0xFFFFFDE7);
const Color cAuditText = Color(0xFFF57F17);

class StockTransactionsScreen extends StatefulWidget {
  const StockTransactionsScreen({super.key});

  @override
  State<StockTransactionsScreen> createState() => _StockTransactionsScreenState();
}

class _StockTransactionsScreenState extends State<StockTransactionsScreen> {
  static const _filters = [
    (null, 'Tất cả loại'),
    ('IMPORT', 'Nhập Kho'),
    ('EXPORT', 'Xuất Kho'),
    ('RECIPE_DEDUCTION', 'Bán Hàng'),
    ('AUDIT_ADJUSTMENT', 'Kiểm Kê'),
  ];

  static const _timeFilters = [
    ('ALL', 'Mọi lúc'),
    ('TODAY', 'Hôm nay'),
    ('WEEK', '7 ngày qua'),
    ('MONTH', '30 ngày qua'),
  ];

  late final StockApi _api;
  String? _type;
  String _timeFilter = 'ALL';
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

  void _onTimeChanged(String? val) {
    if (val == null) return;
    setState(() {
      _timeFilter = val;
      final now = DateTime.now();
      switch (_timeFilter) {
        case 'TODAY':
          _dateRange = DateTimeRange(start: DateTime(now.year, now.month, now.day), end: now);
          break;
        case 'WEEK':
          _dateRange = DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
          break;
        case 'MONTH':
          _dateRange = DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);
          break;
        default:
          _dateRange = null;
      }
    });
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
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Không tải được lịch sử giao dịch');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBgWhite,
      appBar: AppBar(
        backgroundColor: cBgWhite,
        foregroundColor: cBrownDark,
        elevation: 0,
        leadingWidth: 110,
        leading: InkWell(
          onTap: () => Navigator.of(context).pop(),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_back, color: cTextMuted, size: 20),
              SizedBox(width: 4),
              Text('Quay lại', style: TextStyle(color: cTextMuted, fontSize: 16, fontFamily: 'Segoe UI')),
            ],
          ),
        ),
        title: const Text(
          'Lịch Sử Giao Dịch',
          style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 22, color: cBrownDark),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Box
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: cBgWhite,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cBorderLight),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _timeFilter,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, color: cTextMuted),
                        items: _timeFilters.map((f) => DropdownMenuItem(
                          value: f.$1,
                          child: Text(f.$2, style: const TextStyle(fontFamily: 'Segoe UI', color: cBrownDark, fontWeight: FontWeight.bold, fontSize: 14)),
                        )).toList(),
                        onChanged: _onTimeChanged,
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: cBorderLight,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _type,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, color: cTextMuted),
                        items: _filters.map((f) => DropdownMenuItem(
                          value: f.$1,
                          child: Text(f.$2, style: const TextStyle(fontFamily: 'Segoe UI', color: cBrownDark, fontWeight: FontWeight.bold, fontSize: 14)),
                        )).toList(),
                        onChanged: (val) {
                          setState(() => _type = val);
                          _load();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // List
            Expanded(child: _buildList()),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  side: const BorderSide(color: cBorderLight),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Quay lại Kho hàng', style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, color: cBrownDark, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: cExportText)));
    if (_items.isEmpty) return const Center(child: Text('Chưa có giao dịch nào', style: TextStyle(color: cTextMuted, fontFamily: 'Segoe UI')));
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        return _buildTransactionCard(_items[index]);
      },
    );
  }

  Widget _buildTransactionCard(StockTransaction t) {
    // Parse time
    String timeStr = '';
    if (t.createdAt != null) {
      try {
        final dt = DateTime.parse(t.createdAt!).toLocal();
        timeStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    Color badgeBg;
    Color badgeText;
    String typeLabel;
    String qtyPrefix = '';
    
    switch (t.transactionType) {
      case 'IMPORT':
        badgeBg = cImportBg;
        badgeText = cImportText;
        typeLabel = 'Nhập Kho';
        qtyPrefix = '+';
        break;
      case 'EXPORT':
        badgeBg = cExportBg;
        badgeText = cExportText;
        typeLabel = 'Xuất Kho';
        break;
      case 'AUDIT_ADJUSTMENT':
        badgeBg = cAuditBg;
        badgeText = cAuditText;
        typeLabel = 'Kiểm Kê';
        qtyPrefix = t.quantity > 0 ? '+' : '';
        break;
      default:
        badgeBg = const Color(0xFFF5F5F5);
        badgeText = const Color(0xFF616161);
        typeLabel = 'Khác';
        qtyPrefix = t.quantity > 0 ? '+' : '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cBgWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(timeStr, style: const TextStyle(color: cTextMuted, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Segoe UI')),
              Text('Người thực hiện: ${t.managerName ?? 'Manager'}', style: const TextStyle(color: cTextMuted, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Segoe UI')),
            ],
          ),
          const SizedBox(height: 12),
          
          // Title row
          Row(
            children: [
              Expanded(
                child: Text(
                  t.materialName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cBrownDark, fontFamily: 'Segoe UI'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(left: 8, right: 8),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(typeLabel, style: TextStyle(color: badgeText, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Segoe UI')),
              ),
              Text(
                '$qtyPrefix${formatVnd(t.quantity)}',
                style: TextStyle(fontWeight: FontWeight.bold, color: badgeText, fontSize: 16, fontFamily: 'Segoe UI'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Inner box details
          _buildDetails(t),
        ],
      ),
    );
  }

  Widget _buildDetails(StockTransaction t) {
    List<Widget> rows = [];
    
    if (t.transactionType == 'IMPORT') {
      rows.add(_buildDetailRow('Nhà CC:', 'Nhà cung cấp nội bộ'));
      rows.add(_buildDetailRow('Đơn giá:', 'Theo hệ thống'));
      rows.add(_buildDetailRow('Ghi chú:', t.reason ?? '-'));
    } else if (t.transactionType == 'EXPORT') {
      rows.add(_buildDetailRow('Lý do:', 'Xuất kho / Hủy'));
      rows.add(_buildDetailRow('Ghi chú:', t.reason ?? '-'));
    } else if (t.transactionType == 'AUDIT_ADJUSTMENT') {
      rows.add(_buildDetailRow('Kiểm kê thực tế:', '${formatVnd(t.quantityAfter)} (Hệ thống: ${formatVnd(t.quantityBefore)})'));
      rows.add(_buildDetailRow('Sai lệch:', '${t.quantity > 0 ? '+' : ''}${formatVnd(t.quantity)}'));
      rows.add(_buildDetailRow('Ghi chú giải trình:', t.reason ?? '-'));
    } else {
      rows.add(_buildDetailRow('Ghi chú:', t.reason ?? '-'));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFBF8F6),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
          topLeft: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
        border: Border(left: BorderSide(color: cBorderLight, width: 4)),
      ),
      child: Column(
        children: rows,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: cBrownDark, fontSize: 13, fontFamily: 'Segoe UI')),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: cTextMuted, fontSize: 13, fontFamily: 'Segoe UI'), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
