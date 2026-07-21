import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/order_api.dart';
import '../auth/auth_controller.dart';
import '../auth/logout_screen.dart';
import '../profile/profile_screen.dart';
import '../theme.dart';
import 'order_detail_screen.dart';
import 'print_sticker_dialog.dart';

/// Barista Monitor Portal — redesigned to match Figma Node 149:2587.
class BaristaPortalScreen extends StatefulWidget {
  const BaristaPortalScreen({super.key});

  @override
  State<BaristaPortalScreen> createState() => _BaristaPortalScreenState();
}

class _BaristaPortalScreenState extends State<BaristaPortalScreen> {
  late final OrderApi _api;
  List<OrderDetail> _orders = const [];
  bool _loading = true;
  bool _refreshing = false;
  Timer? _refreshTimer;
  String? _busyId;
  String? _error;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _api = OrderApi(context.read<ApiClient>());
    _load();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => unawaited(_load(silent: true)),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (_refreshing) return;
    _refreshing = true;
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final summaries = await _api.queue();
      final details = <OrderDetail>[];
      for (final s in summaries) {
        try {
          details.add(await _api.detail(s.id));
        } catch (_) {}
      }
      if (mounted) setState(() => _orders = details);
    } catch (e) {
      if (mounted && !silent) {
        setState(
          () => _error = e is ApiException
              ? e.message
              : 'Không tải được hàng đợi',
        );
      }
    } finally {
      _refreshing = false;
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  Future<void> _advance(OrderDetail o, String target) async {
    setState(() => _busyId = o.id);
    try {
      final res = await _api.updateStatus(o.id, target);
      if (!mounted) return;
      setState(() {
        if (res.status == 'COMPLETED' ||
            res.status == 'CANCELLED' ||
            res.status == 'ABANDONED') {
          _orders = _orders.where((order) => order.id != o.id).toList();
        } else {
          _orders = _orders
              .map(
                (order) =>
                    order.id == o.id ? order.withStatus(res.status) : order,
              )
              .toList();
        }
      });
      if (res.stockWarnings.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: kDanger,
            content: Text(res.stockWarnings.join('\n')),
          ),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ApiException ? e.message : 'Cập nhật thất bại'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final storeName = auth.profile?.storeName ?? 'Nguyễn Du';
    final compactHeader = MediaQuery.sizeOf(context).width < 1000;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D2314),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          compactHeader ? 'Quầy Pha Chế' : 'Quầy Pha Chế (Barista Monitor)',
          style: const TextStyle(
            fontFamily: 'Segoe UI',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (!compactHeader)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Chi nhánh: $storeName | Quầy: BAR-01',
                  style: const TextStyle(
                    fontFamily: 'Segoe UI',
                    color: Color(0xFFEADDD3),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Tài khoản',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            ),
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Color(0xFFEADDD3),
            ),
          ),
          IconButton(
            key: const Key('portal-refresh'),
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh, color: Color(0xFFEADDD3)),
            onPressed: _load,
          ),
          IconButton(
            key: const Key('portal-logout'),
            tooltip: 'Đăng xuất',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const LogoutScreen()),
            ),
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3D2314)),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: kDanger, fontFamily: 'Segoe UI'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D2314),
              ),
              child: const Text(
                'Thử lại',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    final pendingOrders = _orders.where((o) => o.status == 'PENDING').toList();
    final preparingOrders = _orders
        .where(
          (o) =>
              o.status == 'PREPARING' ||
              o.status == 'HOLD' ||
              o.status == 'READY',
        )
        .toList();

    return Row(
      key: const Key('portal-grid'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _buildColumn('Đơn Chờ Pha Chế (Pending)', pendingOrders),
        ),
        const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFEADDD3)),
        Expanded(
          child: _buildColumn('Đang Thực Hiện (Preparing)', preparingOrders),
        ),
      ],
    );
  }

  Widget _buildColumn(String title, List<OrderDetail> orders) {
    return Column(
      children: [
        // Column Header per Figma 149:2587
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF5EEE8),
            border: Border(bottom: BorderSide(color: Color(0xFFEADDD3))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Segoe UI',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5C3826),
                  fontSize: 12,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF3D2314),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${orders.length}',
                  style: const TextStyle(
                    fontFamily: 'Segoe UI',
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: orders.isEmpty
              ? const Center(
                  child: Text(
                    'Không có đơn hàng',
                    style: TextStyle(
                      color: Color(0xFF8C766C),
                      fontFamily: 'Segoe UI',
                      fontSize: 13,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
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
    final isReady = o.status == 'READY';

    final rawNum = o.orderNumber ?? '';
    final formattedNum = rawNum.length >= 3
        ? rawNum.substring(rawNum.length - 3)
        : rawNum.padLeft(3, '0');

    // Calculate wait time text safely
    String waitText = isPending ? 'Chờ 5m' : 'Đang pha 10m';
    if (o.createdAt != null && o.createdAt!.isNotEmpty) {
      try {
        final parsed = DateTime.parse(o.createdAt!);
        final diffMin = DateTime.now().difference(parsed).inMinutes.abs();
        waitText = isPending
            ? (diffMin == 0 ? 'Vừa vào' : 'Chờ ${diffMin}m')
            : 'Đang pha ${diffMin}m';
      } catch (_) {}
    }

    // Channel/type badge check
    final orderTypeStr = o.orderType ?? '';
    final isShopeeFood = orderTypeStr == 'DELIVERY' || o.id.contains('shopee');

    final itemsList = o.items ?? [];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isHold ? const Color(0xFFFFF4F4) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isHold ? const Color(0xFFCF6679) : const Color(0xFFEADDD3),
            width: isHold ? 1.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.02),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Top Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Đơn #$formattedNum',
                      style: TextStyle(
                        fontFamily: 'Segoe UI',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isHold
                            ? const Color(0xFFCF6679)
                            : const Color(0xFF2C1A11),
                      ),
                    ),
                    if (isShopeeFood) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(
                              0xFFE65100,
                            ).withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Text(
                          'ĐƠN SHOPEEFOOD',
                          style: TextStyle(
                            fontFamily: 'Segoe UI',
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE65100),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  waitText,
                  style: const TextStyle(
                    fontFamily: 'Segoe UI',
                    color: Color(0xFF8C766C),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Items Container per Figma 149:2587
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: itemsList.map((item) {
                  final qty = item.quantity ?? 1;
                  final name = item.menuItemName ?? 'Món';
                  final toppingsList = item.toppings ?? [];
                  final toppingsText = toppingsList
                      .map((t) => t.name ?? '')
                      .where((n) => n.isNotEmpty)
                      .join(', ');
                  final detailsText = toppingsText.isNotEmpty
                      ? '- $toppingsText'
                      : '';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${qty}x $name',
                          style: const TextStyle(
                            fontFamily: 'Segoe UI',
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF3D2314),
                          ),
                        ),
                        if (detailsText.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              detailsText,
                              style: const TextStyle(
                                fontFamily: 'Segoe UI',
                                color: Color(0xFF8C766C),
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),

            // Action Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isPending)
                  ElevatedButton(
                    key: Key('portal-advance-${o.id}-PREPARING'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D2314),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: busy ? null : () => _advance(o, 'PREPARING'),
                    child: busy
                        ? const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'BẮT ĐẦU PHA CHẾ',
                            style: TextStyle(
                              fontFamily: 'Arial',
                              fontSize: 10.9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  )
                else if (isHold)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC89D7C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: busy ? null : () => _advance(o, 'PREPARING'),
                    child: busy
                        ? const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'TIẾP TỤC PHA',
                            style: TextStyle(
                              fontFamily: 'Arial',
                              fontSize: 10.9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  )
                else if (isReady)
                  ElevatedButton(
                    key: Key('portal-advance-${o.id}-COMPLETED'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: busy ? null : () => _advance(o, 'COMPLETED'),
                    child: const Text(
                      'ĐÃ GIAO KHÁCH',
                      style: TextStyle(
                        fontFamily: 'Arial',
                        fontSize: 10.9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else ...[
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFCF6679),
                      side: const BorderSide(color: Color(0x4DCF6679)),
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: busy ? null : () => _advance(o, 'HOLD'),
                    child: const Text(
                      'BÁO LỖI',
                      style: TextStyle(
                        fontFamily: 'Segoe UI',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    key: Key('portal-advance-${o.id}-COMPLETED'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: busy ? null : () => _advance(o, 'COMPLETED'),
                    child: busy
                        ? const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'HOÀN THÀNH',
                            style: TextStyle(
                              fontFamily: 'Arial',
                              fontSize: 10.9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
