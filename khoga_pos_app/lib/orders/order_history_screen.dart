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
    ('CANCELLED', 'Đã hủy'),
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

    if (isCashier && shift == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline, size: 48, color: Color(0xFF8C766C)),
                        SizedBox(height: 16),
                        Text('Bạn cần mở ca trước khi xem lịch sử đơn hàng.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF8C766C), fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              ),
              _buildBottomButton(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: SizedBox(
                height: 38,
                child: TextField(
                  key: const Key('order-history-search'),
                  decoration: InputDecoration(
                    hintText: 'Tìm số đơn hàng, mã đơn...',
                    hintStyle: const TextStyle(fontFamily: 'Arial', fontSize: 13, color: Color(0xFF8C766C)),
                    prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF8C766C)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 0),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFEADDD3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFC89D7C)),
                    ),
                  ),
                  onChanged: (v) => setState(() => _search = v.trim()),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 38,
                child: DropdownButtonFormField<String?>(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFFAFAFA),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 0),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFEADDD3)),
                    ),
                  ),
                  value: _status,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF8C766C)),
                  items: _filters.map((f) => DropdownMenuItem(
                    value: f.$1,
                    child: Text(f.$2, style: const TextStyle(fontFamily: 'Segoe UI', fontSize: 13, color: Color(0xFF2C1A11))),
                  )).toList(),
                  onChanged: _selectFilter,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: RefreshIndicator(onRefresh: _load, child: _list())),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              children: [
                const Icon(Icons.arrow_back_ios, size: 14, color: Color(0xFF8C766C)),
                const SizedBox(width: 4),
                const Text('Quay lại', style: TextStyle(fontFamily: 'Segoe UI', fontSize: 14, color: Color(0xFF8C766C))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text('Đơn Hàng Chi Nhánh', style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 19, color: Color(0xFF2C1A11))),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFEADDD3)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Quay lại bán hàng',
            style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF3D2314)),
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
    
    final filtered = _orders.where((o) => _search.isEmpty || o.orderNumber.toLowerCase().contains(_search.toLowerCase())).toList();
    
    if (filtered.isEmpty) {
      return const Center(child: Text('Không tìm thấy đơn hàng phù hợp', style: TextStyle(color: kMuted)));
    }
    return ListView.separated(
      key: const Key('order-list'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _row(filtered[i]),
    );
  }

  Widget _row(OrderSummary o) {
    Color bg, text;
    String statusStr;
    switch (o.status) {
      case 'PENDING':
      case 'PREPARING':
        bg = const Color(0xFFE3F2FD);
        text = const Color(0xFF1565C0);
        statusStr = 'Đang pha chế';
        break;
      case 'READY':
        bg = const Color(0xFFFFF8E1);
        text = const Color(0xFFB78103);
        statusStr = 'Chờ lấy hàng';
        break;
      case 'COMPLETED':
        bg = const Color(0xFFE8F5E9);
        text = const Color(0xFF2E7D32);
        statusStr = 'Hoàn thành';
        break;
      case 'CANCELLED':
        bg = const Color(0xFFFDE8EB);
        text = const Color(0xFFCF6679);
        statusStr = 'Đã hủy đơn';
        break;
      default:
        bg = const Color(0xFFF5F5F5);
        text = const Color(0xFF757575);
        statusStr = o.status;
    }

    String timeStr = '--:--';
    if (o.createdAt != null) {
      try {
        final dt = DateTime.parse(o.createdAt!);
        timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return GestureDetector(
      key: Key('order-row-${o.id}'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => OrderDetailScreen(orderId: o.id)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFDFDFD),
          border: Border.all(color: const Color(0xFFEADDD3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Đơn ${o.orderNumber} (${o.orderType == 'DINE_IN' ? 'Dine-in' : 'Take-away'})',
                    style: const TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2C1A11)),
                  ),
                  Text(
                    'Thời gian: $timeStr | Mã: ${o.id.split('-').last}',
                    style: const TextStyle(fontFamily: 'Segoe UI', fontSize: 11, color: Color(0xFF8C766C)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${formatVnd(o.total)} đ',
                  style: const TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF3D2314)),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusStr,
                    style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 9, color: text),
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
