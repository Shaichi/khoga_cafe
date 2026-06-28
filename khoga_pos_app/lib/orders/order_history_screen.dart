import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    ('CANCELLED', 'Đã hủy'),
  ];

  late final OrderApi _api;
  String? _status;
  List<OrderSummary> _orders = const [];
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
      final list = await _api.history(status: _status);
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrown,
        foregroundColor: Colors.white,
        title: const Text('Lịch sử đơn hàng'),
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
                        key: Key('filter-${f.$1 ?? 'ALL'}'),
                        label: Text(f.$2),
                        selected: _status == f.$1,
                        onSelected: (_) => _selectFilter(f.$1),
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
    if (_error != null) {
      return Center(child: Text(_error!, key: const Key('order-history-error'), style: const TextStyle(color: kDanger)));
    }
    if (_orders.isEmpty) {
      return const Center(child: Text('Chưa có đơn hàng nào', style: TextStyle(color: kMuted)));
    }
    return ListView.separated(
      key: const Key('order-list'),
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _row(_orders[i]),
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
          subtitle: Text('${o.itemCount} món · ${paymentMethodLabel(o.paymentMethod)}'
              '${o.customerName != null ? ' · ${o.customerName}' : ''}'),
          trailing: Text('${formatVnd(o.total)} VND', style: const TextStyle(fontWeight: FontWeight.w600, color: kBrown)),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => OrderDetailScreen(orderId: o.id)),
          ),
        ),
      );
}
