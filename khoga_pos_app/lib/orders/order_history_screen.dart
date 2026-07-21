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

/// Screen 49 — branch order history (UC-54). A status filter scopes the list;
/// tapping a row opens the detail screen (40).
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late final OrderApi _api;
  String? _status;
  final DateTime _startDate = DateTime.now();
  final DateTime _endDate = DateTime.now();
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

  // Filter feature removed from UI matching Figma

  @override
  Widget build(BuildContext context) {
    final role = context.read<AuthController>().profile?.role;
    final isCashier = role == 'CASHIER';
    final shift = context.read<ShiftController>().active;

    // Cashier chưa mở ca → chặn truy cập
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

    final isManager = role == 'STORE_MANAGER';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: kBrownDark,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back, color: kMuted, size: 20),
                  const SizedBox(width: 4),
                  const Text('Quay lại', style: TextStyle(color: kMuted, fontSize: 14, fontWeight: FontWeight.normal)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(isManager ? 'Đơn Hàng Chi Nhánh' : 'Lịch sử đơn hàng', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: kBrownDark)),
          ],
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEBEBEB)),
                ),
                alignment: Alignment.centerLeft,
                child: TextField(
                  key: const Key('order-history-search'),
                  maxLength: 50,
                  decoration: const InputDecoration(
                    hintText: 'Tìm số đơn hàng, mã đơn...',
                    hintStyle: TextStyle(color: kMuted, fontSize: 14),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    counterText: '',
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) => setState(() => _search = v.trim()),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                height: 48,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEBEBEB)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _status,
                    isExpanded: true,
                    hint: const SizedBox(),
                    icon: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('', style: TextStyle(color: kMuted, fontSize: 14))),
                      DropdownMenuItem(value: 'PENDING', child: Text('Chờ pha chế', style: TextStyle(color: kBrownDark, fontSize: 14))),
                      DropdownMenuItem(value: 'PREPARING', child: Text('Đang pha chế', style: TextStyle(color: kBrownDark, fontSize: 14))),
                      DropdownMenuItem(value: 'READY', child: Text('Chờ lấy hàng', style: TextStyle(color: kBrownDark, fontSize: 14))),
                      DropdownMenuItem(value: 'COMPLETED', child: Text('Hoàn thành', style: TextStyle(color: kBrownDark, fontSize: 14))),
                      DropdownMenuItem(value: 'CANCELLED', child: Text('Đã hủy', style: TextStyle(color: kBrownDark, fontSize: 14))),
                    ],
                    onChanged: (v) {
                      setState(() => _status = v);
                      _load();
                    },
                  ),
                ),
              ),
            ),
            Expanded(child: RefreshIndicator(onRefresh: _load, child: _list())),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEBEBEB))),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: kBrownDark,
                side: const BorderSide(color: Color(0xFFEBEBEB)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Quay lại bán hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _list() {
    if (_loading) return const Center(child: Text('Đang tải…'));
    if (_error != null) {
      return Center(child: Text(_error!, key: const Key('order-history-error'), style: const TextStyle(color: kDanger)));
    }
    
    final filtered = _orders.where((o) => _search.isEmpty || o.orderNumber.toLowerCase().contains(_search.toLowerCase()) || o.id.toLowerCase().contains(_search.toLowerCase())).toList();
    
    if (filtered.isEmpty) {
      return const Center(child: Text('Không tìm thấy đơn hàng phù hợp', style: TextStyle(color: kMuted)));
    }
    return ListView.separated(
      key: const Key('order-list'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _row(filtered[i]),
    );
  }

  Widget _row(OrderSummary o) {
    String time = '--:--';
    if (o.createdAt != null) {
      try {
        final dt = DateTime.parse(o.createdAt!).toLocal();
        time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }
    final orderTypeStr = o.orderType == 'DINE_IN' ? 'Dine-in' : 'Take-away';
    final orderNumberStr = o.orderNumber.startsWith('#') ? o.orderNumber : '#${o.orderNumber}';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => OrderDetailScreen(orderId: o.id)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEBEBEB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Đơn $orderNumberStr ($orderTypeStr)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kBrownDark)),
                Text('${formatVnd(o.total)} đ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kBrownDark)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Thời gian: $time | Mã: ORD-${o.id.substring(0, 4)}', style: const TextStyle(color: kMuted, fontSize: 13)),
                _buildStatusBadge(o.status),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg, fg;
    String text;
    switch (status) {
      case 'PENDING':
      case 'PREPARING':
        bg = const Color(0xFFE3F2FD);
        fg = const Color(0xFF1565C0);
        text = status == 'PENDING' ? 'Chờ pha chế' : 'Đang pha chế';
        break;
      case 'READY':
        bg = const Color(0xFFFFF9C4);
        fg = const Color(0xFFB78103);
        text = 'Chờ lấy hàng';
        break;
      case 'COMPLETED':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        text = 'Hoàn thành';
        break;
      case 'CANCELLED':
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        text = 'Đã hủy đơn';
        break;
      default:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
        text = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bg, Colors.white.withOpacity(0.0)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
