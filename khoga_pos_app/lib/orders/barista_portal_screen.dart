import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/order_api.dart';
import '../auth/auth_controller.dart';
import '../theme.dart';
import 'order_labels.dart';
import 'order_detail_screen.dart';
import 'print_sticker_dialog.dart';

class BaristaPortalScreen extends StatefulWidget {
  const BaristaPortalScreen({super.key});

  @override
  State<BaristaPortalScreen> createState() => _BaristaPortalScreenState();
}

class _BaristaPortalScreenState extends State<BaristaPortalScreen> {
  late final OrderApi _api;
  List<OrderDetail> _orders = const [];
  bool _loading = true;
  String? _busyId;
  String? _error;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(
      const [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
    );
    _api = OrderApi(context.read<ApiClient>());
    _load();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summaries = await _api.queue();
      final details = <OrderDetail>[];
      for (final s in summaries) {
        details.add(await _api.detail(s.id));
      }
      if (mounted) setState(() => _orders = details);
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Không tải được hàng đợi');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _advance(OrderDetail o, String target) async {
    setState(() => _busyId = o.id);
    try {
      final res = await _api.updateStatus(o.id, target);
      if (!mounted) return;
      if (res.stockWarnings.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: kDanger, content: Text(res.stockWarnings.join('\n'))),
        );
      }
      
      // If we just advanced to PREPARING, pop up the print sticker dialog
      if (target == 'PREPARING') {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => PrintStickerDialog(order: o),
        );
      }
      
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : 'Cập nhật thất bại')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F5),
      appBar: AppBar(
        backgroundColor: kBrown,
        foregroundColor: Colors.white,
        title: Text('Quầy Pha Chế (Barista Monitor)'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () => _showProfileDialog(context, auth),
                child: Text('Chi nhánh: TT Q1 | Tài khoản: ${auth.profile?.fullName ?? ''}', style: const TextStyle(decoration: TextDecoration.underline)),
              ),
            ),
          ),
          IconButton(
            key: const Key('portal-refresh'),
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
          TextButton.icon(
            key: const Key('portal-logout'),
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
            onPressed: auth.logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: Text('Đang tải…'));
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: kDanger)));
    
    final pendingOrders = _orders.where((o) => o.status == 'PENDING').toList();
    final preparingOrders = _orders.where((o) => o.status == 'PREPARING' || o.status == 'HOLD').toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _buildColumn('Đơn Chờ Pha Chế (Pending)', pendingOrders),
        ),
        const VerticalDivider(width: 1, color: Color(0xFFE5E0DA)),
        Expanded(
          child: _buildColumn('Đang Thực Hiện (Preparing)', preparingOrders),
        ),
      ],
    );
  }

  Widget _buildColumn(String title, List<OrderDetail> orders) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFF0EBE5),
            border: Border(bottom: BorderSide(color: Color(0xFFE5E0DA))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: kBrown, fontSize: 16)),
              CircleAvatar(
                radius: 12,
                backgroundColor: kBrown,
                child: Text('${orders.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (_, i) => _card(orders[i]),
          ),
        ),
      ],
    );
  }

  Widget _card(OrderDetail o) {
    final busy = _busyId == o.id;
    final isPending = o.status == 'PENDING';
    final isHold = o.status == 'HOLD';
    
    // Simulate wait time since createdAt
    final waitText = isPending ? 'Chờ 5m' : 'Đang pha 10m';

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isHold ? const Color(0xFFFFF4F4) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isHold ? kDanger : const Color(0xFFE5E0DA), width: isHold ? 2 : 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(o.orderNumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrown), overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Text(waitText, style: const TextStyle(color: kMuted, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F7F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: (o.items ?? []).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item.quantity ?? 1}x ${item.menuItemName ?? 'Món'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        if ((item.toppings ?? []).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 8),
                            child: Text('- ${item.toppings.map((t) => t.name).join(', ')}', style: const TextStyle(color: kMuted, fontSize: 13)),
                          )
                      ],
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (isPending)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBrown,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: busy ? null : () => _advance(o, 'PREPARING'),
                      child: busy
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('BẮT ĐẦU PHA CHẾ'),
                    )
                  else if (isHold)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGold,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: busy ? null : () => _advance(o, 'PREPARING'),
                      child: busy
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87))
                          : const Text('TIẾP TỤC PHA'),
                    )
                  else ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kDanger,
                        side: const BorderSide(color: kDanger, width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: busy ? null : () => _advance(o, 'HOLD'),
                      child: const Text('BÁO LỖI'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kSuccess,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: busy ? null : () => _advance(o, 'READY'),
                      child: busy
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('HOÀN THÀNH'),
                    ),
                  ]
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileDialog(BuildContext context, auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thông tin tài khoản'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nhân viên: ${auth.profile?.fullName ?? 'Không rõ'}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Tài khoản: ${auth.profile?.username ?? ''}'),
            const SizedBox(height: 8),
            Text('Vai trò: ${auth.profile?.role ?? ''}'),
            const SizedBox(height: 8),
            Text('Mã chi nhánh: ${auth.profile?.storeId ?? 'N/A'}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ĐÓNG')),
        ],
      ),
    );
  }
}
