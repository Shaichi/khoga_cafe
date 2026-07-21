import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/order_api.dart';
import '../format.dart';
import '../theme.dart';
import 'manager_order_detail_screen.dart';

class ManagerOrderHistoryScreen extends StatefulWidget {
  const ManagerOrderHistoryScreen({super.key});

  @override
  State<ManagerOrderHistoryScreen> createState() => _ManagerOrderHistoryScreenState();
}

class _ManagerOrderHistoryScreenState extends State<ManagerOrderHistoryScreen> {

  late final OrderApi _api;
  String? _status;
  List<OrderSummary> _orders = const [];
  String _search = '';
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

  String _statusLabel(String? status) {
    switch (status) {
      case 'PENDING': return 'Chờ pha chế';
      case 'PREPARING': return 'Đang pha chế';
      case 'READY': return 'Chờ lấy hàng';
      case 'COMPLETED': return 'Hoàn thành';
      case 'CANCELLED': return 'Đã hủy';
      default: return 'Tất cả trạng thái';
    }
  }

  void _showFilterSheet() {
    String? tempStatus = _status;
    DateTime tempFrom = _fromDate;
    DateTime tempTo = _toDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Bộ lọc đơn hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kBrownDark)),
                  const SizedBox(height: 24),
                  const Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold, color: kMuted)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip('Tất cả', null, tempStatus, (v) => setSheetState(() => tempStatus = v)),
                      _buildChip('Chờ pha chế', 'PENDING', tempStatus, (v) => setSheetState(() => tempStatus = v)),
                      _buildChip('Đang pha chế', 'PREPARING', tempStatus, (v) => setSheetState(() => tempStatus = v)),
                      _buildChip('Chờ lấy hàng', 'READY', tempStatus, (v) => setSheetState(() => tempStatus = v)),
                      _buildChip('Hoàn thành', 'COMPLETED', tempStatus, (v) => setSheetState(() => tempStatus = v)),
                      _buildChip('Đã hủy', 'CANCELLED', tempStatus, (v) => setSheetState(() => tempStatus = v)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Thời gian', style: TextStyle(fontWeight: FontWeight.bold, color: kMuted)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: DateTimeRange(start: tempFrom, end: tempTo),
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
                        setSheetState(() {
                          tempFrom = picked.start;
                          tempTo = picked.end;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEBEBEB)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tempFrom.year == tempTo.year && tempFrom.month == tempTo.month && tempFrom.day == tempTo.day
                                ? '${tempFrom.day}/${tempFrom.month}/${tempFrom.year}'
                                : '${tempFrom.day}/${tempFrom.month}/${tempFrom.year} - ${tempTo.day}/${tempTo.month}/${tempTo.year}',
                            style: const TextStyle(color: kBrownDark, fontSize: 15),
                          ),
                          const Icon(Icons.date_range, color: kMuted, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _status = tempStatus;
                        _fromDate = tempFrom;
                        _toDate = tempTo;
                      });
                      _load();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBrownDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('ÁP DỤNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildChip(String label, String? value, String? groupValue, ValueChanged<String?> onSelected) {
    final isSelected = value == groupValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      selectedColor: kBrown,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : kBrownDark,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? kBrown : const Color(0xFFEBEBEB)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        leadingWidth: 100,
        leading: Row(
          children: [
            IconButton(
              padding: const EdgeInsets.only(left: 16, right: 4),
              icon: const Icon(Icons.arrow_back, color: kMuted),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const Text('Quay lại', style: TextStyle(color: kMuted, fontSize: 14)),
          ],
        ),
        title: const Text('Đơn Hàng Chi Nhánh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEBEBEB)),
                ),
                alignment: Alignment.centerLeft,
                child: TextField(
                  key: const Key('manager-order-history-search'),
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
                    prefixIcon: Icon(Icons.search, color: kMuted),
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (v) => setState(() => _search = v.trim()),
                ),
              ),
            ),
            // Filter Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GestureDetector(
                onTap: _showFilterSheet,
                child: Container(
                  height: 48,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEBEBEB)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_statusLabel(_status)} | ${_fromDate.day}/${_fromDate.month} - ${_toDate.day}/${_toDate.month}',
                        style: const TextStyle(color: kBrownDark, fontSize: 14),
                      ),
                      const Icon(Icons.tune, color: kMuted, size: 20),
                    ],
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
        MaterialPageRoute<void>(builder: (_) => ManagerOrderDetailScreen(orderId: o.id)),
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
            const SizedBox(height: 12),
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
        fg = Colors.grey;
        text = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bg, Colors.white.withValues(alpha: 0.0)],
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
