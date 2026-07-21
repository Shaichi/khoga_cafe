import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/order_api.dart';
import '../format.dart';
import '../theme.dart';
import '../orders/order_labels.dart';
import 'manager_order_detail_screen.dart';

class ManagerOrderHistoryScreen extends StatefulWidget {
  const ManagerOrderHistoryScreen({super.key});

  @override
  State<ManagerOrderHistoryScreen> createState() => _ManagerOrderHistoryScreenState();
}

class _ManagerOrderHistoryScreenState extends State<ManagerOrderHistoryScreen> {
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

  DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime.now();

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
      final list = await _api.history(status: _status, startDate: _fromDate, endDate: _toDate);
      if (mounted) setState(() => _orders = list);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is ApiException ? e.message : 'Không tải được lịch sử đơn');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectFilter(String? status) {
    setState(() => _status = status);
    _load();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kBrownDark,
              onPrimary: Colors.white,
              onSurface: kBrownDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: kBrownDark,
        elevation: 0,
        title: const Text(
          'Lịch Sử Đơn Hàng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Date Filter
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.date_range, color: kBrownDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectDateRange,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: kBorder),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_fromDate.day}/${_fromDate.month}/${_fromDate.year}  -  ${_toDate.day}/${_toDate.month}/${_toDate.year}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: kBrownDark),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Status Filter row
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _filters.map((f) {
                    final isSelected = _status == f.$1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          f.$2,
                          style: TextStyle(
                            color: isSelected ? Colors.white : kBrownDark,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) => _selectFilter(f.$1),
                        selectedColor: kBrown,
                        backgroundColor: Colors.white,
                        side: BorderSide(color: isSelected ? kBrown : kBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // List
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kBrownDark));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: kDanger)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: kBrownDark),
              child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    if (_orders.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có đơn hàng nào',
          style: TextStyle(color: kMuted, fontSize: 16),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: kBrownDark,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _buildOrderCard(_orders[i]),
      ),
    );
  }

  Widget _buildOrderCard(OrderSummary o) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ManagerOrderDetailScreen(orderId: o.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  o.orderNumber,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kBrownDark,
                  ),
                ),
                StatusChip(o.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.receipt_long, size: 16, color: kMuted),
                const SizedBox(width: 4),
                Text(
                  '${o.itemCount} món',
                  style: const TextStyle(color: kMuted),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.payment, size: 16, color: kMuted),
                const SizedBox(width: 4),
                Text(
                  paymentMethodLabel(o.paymentMethod),
                  style: const TextStyle(color: kMuted),
                ),
              ],
            ),
            if (o.customerName != null && o.customerName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: kMuted),
                  const SizedBox(width: 4),
                  Text(
                    o.customerName!,
                    style: const TextStyle(color: kMuted),
                  ),
                ],
              ),
            ],
            const Divider(height: 24, color: kBorder),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng tiền', style: TextStyle(fontWeight: FontWeight.bold, color: kBrownDark)),
                Text(
                  '${formatVnd(o.total)}đ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kBrown,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
