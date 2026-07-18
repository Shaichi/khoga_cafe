import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import '../pos/shift_controller.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/order_api.dart';
import '../format.dart';
import '../theme.dart';
import 'order_detail_screen.dart';
import 'order_labels.dart';

/// Screen 49 — branch order history (UC-54). A status filter scopes the list;
/// tapping a row opens the detail screen (40).
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  static const _filters = [
    (null, 'Tất cả'),
    ('COMPLETED', 'Hoàn tất'),
    ('PENDING', 'Chờ xử lý'),
    ('PREPARING', 'Đang pha'),
    ('READY', 'Sẵn sàng'),
    ('HOLD', 'Tạm giữ'),
    ('CANCELLED', 'Đã hủy'),
    ('ABANDONED', 'Bị bỏ rơi'),
  ];

  late final OrderApi _api;
  String? _status;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  List<OrderSummary> _orders = const [];
  String _search = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = OrderApi(context.read<ApiClient>());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.history(
        status: _status,
        startDate: _startDate,
        endDate: _endDate,
      );
      if (mounted) setState(() => _orders = list);
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Không tải được lịch sử đơn');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectFilter(String? status) {
    setState(() => _status = status);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final role = context.read<AuthController>().profile?.role;
    final isCashier = role == 'CASHIER';
    final shift = context.read<ShiftController>().active;

    // Fix 1: Cashier chưa mở ca → chặn truy cập
    if (isCashier && shift == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: kBrown,
          foregroundColor: Colors.white,
          title: const Text('Lịch sử đơn hàng'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 48, color: kMuted),
                SizedBox(height: 16),
                Text('Bạn cần mở ca trước khi xem lịch sử đơn hàng.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kMuted, fontSize: 15)),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrown,
        foregroundColor: Colors.white,
        title: const Text('Lịch sử đơn hàng'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                key: const Key('order-history-search'),
                decoration: const InputDecoration(
                  hintText: 'Tìm theo mã đơn (VD: OD-1234)...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _search = v.trim()),
              ),
            ),
            if (isCashier)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text('Đang hiển thị đơn hàng trong ca hiện tại', style: TextStyle(color: kMuted, fontStyle: FontStyle.italic)),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked.start;
                        _endDate = picked.end;
                      });
                      _load();
                    }
                  },
                  icon: const Icon(Icons.date_range),
                  label: Text('Ngày: ${formatDate(_startDate)} - ${formatDate(_endDate)}'),
                ),
              ),
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
                        key: Key('filter-${f.$1 ?? 'ALL'}'),
                        label: Text(f.$2),
                        selected: _status == f.$1,
                        onSelected: (_) => _selectFilter(f.$1),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(child: RefreshIndicator(onRefresh: _load, child: _list())),
          ],
        ),
      ),
    );
  }

  Widget _list() {
    if (_loading) return const Center(child: Text('Đang tải…'));
    if (_error != null) {
      return Center(child: Text(_error!, key: const Key('order-history-error'), style: const TextStyle(color: kDanger)));
    }
    
    final filtered = _orders.where((o) => _search.isEmpty || o.orderNumber.toLowerCase().contains(_search.toLowerCase())).toList();
    
    if (filtered.isEmpty) {
      return const Center(child: Text('Không tìm thấy đơn hàng phù hợp', style: TextStyle(color: kMuted)));
    }
    return ListView.separated(
      key: const Key('order-list'),
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _row(filtered[i]),
    );
  }

  Widget _row(OrderSummary o) => Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          key: Key('order-row-${o.id}'),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(o.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
              StatusChip(o.status),
            ],
          ),
          subtitle: Text(_buildSubtitle(o)),
          trailing: Text('${formatVnd(o.total)} VND', style: const TextStyle(fontWeight: FontWeight.w600, color: kBrown)),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => OrderDetailScreen(orderId: o.id)),
          ),
        ),
      );

  String _buildSubtitle(OrderSummary o) {
    final parts = <String>[];
    if (o.createdAt != null) {
      try {
        final dt = DateTime.parse(o.createdAt!);
        parts.add('${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}');
      } catch (_) {}
    }
    parts.add('${o.itemCount} món');
    parts.add(paymentMethodLabel(o.paymentMethod));
    if (o.customerName != null) parts.add(o.customerName!);
    return parts.join(' · ');
  }
}
