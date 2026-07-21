import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/order_api.dart';
import '../auth/auth_controller.dart';
import '../auth/logout_confirm_modal.dart';
import '../theme.dart';
import '../profile/profile_screen.dart';
import 'order_labels.dart';
import 'order_detail_screen.dart';

/// Screen 57/58 (landscape) — the Barista Portal. This is the role-home for a
/// BARISTA: instead of the portrait staff Home + cash-register shift gate, the
/// barista lands straight on the live queue, laid out as a wide multi-column
/// board (Figma 736×414). Cards advance through the order lifecycle (UC-58) and
/// recipe-deduction stock warnings (BR-89) surface in a snackbar.
class BaristaQueueScreen extends StatefulWidget {
  final bool isStandalone;
  const BaristaQueueScreen({super.key, this.isStandalone = true});

  @override
  State<BaristaQueueScreen> createState() => _BaristaQueueScreenState();
}

class _BaristaQueueScreenState extends State<BaristaQueueScreen> {
  late final OrderApi _api;
  List<OrderSummary> _orders = const [];
  bool _loading = true;
  String? _busyId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = OrderApi(context.read<ApiClient>());
    _load();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.queue();
      if (mounted) setState(() => _orders = list);
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Không tải được hàng đợi');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _advance(OrderSummary o, String target) async {
    setState(() => _busyId = o.id);
    try {
      final res = await _api.updateStatus(o.id, target);
      if (!mounted) return;
      if (res.stockWarnings.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: kDanger, content: Text(res.stockWarnings.join('\n'))),
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
      appBar: AppBar(
        backgroundColor: kBrown,
        foregroundColor: Colors.white,
        title: Text('Pha chế' + (auth.profile?.storeName != null ? ' · ${auth.profile!.storeName}' : '') + ' · ${auth.profile?.fullName ?? ''}'),
        actions: [
          IconButton(
            key: const Key('portal-refresh'),
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
          if (widget.isStandalone)
            IconButton(
              key: const Key('portal-profile'),
              tooltip: 'Hồ sơ cá nhân',
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
          if (widget.isStandalone)
            IconButton(
              key: const Key('portal-logout'),
              tooltip: 'Đăng xuất',
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => const LogoutConfirmModal(),
                );
                if (confirm == true && context.mounted) {
                  auth.logout();
                }
              },
            ),
        ],
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: Text('Đang tải…'));
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: kDanger)));
    if (_orders.isEmpty) {
      return const Center(
        child: Text('Không có đơn đang chờ', key: Key('portal-empty'), style: TextStyle(color: kMuted, fontSize: 16)),
      );
    }
    return GridView.builder(
      key: const Key('portal-grid'),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisExtent: 200,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _orders.length,
      itemBuilder: (_, i) => _card(_orders[i]),
    );
  }

  Widget _card(OrderSummary o) {
    final next = baristaNextStatus(o.status);
    final busy = _busyId == o.id;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id)),
          );
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(o.orderNumber,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBrown)),
                ),
                const SizedBox(width: 8),
                StatusChip(o.status),
              ],
            ),
            const SizedBox(height: 6),
            Text('${o.itemCount} món · ${orderTypeLabel(o.orderType)}'
                '${o.customerName != null ? ' · ${o.customerName}' : ''}',
                style: const TextStyle(color: kMuted, fontSize: 13)),
            const SizedBox(height: 12),
            if (next.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final n in next)
                      ElevatedButton(
                        key: Key('portal-advance-${o.id}-${n.$1}'),
                        style: n.$1 == 'HOLD' ? ElevatedButton.styleFrom(backgroundColor: kGold) : null,
                        onPressed: busy ? null : () => _advance(o, n.$1),
                        child: busy
                            ? const SizedBox(
                                height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(n.$2.toUpperCase()),
                      ),
                  ],
                ),
              ),
          ],
        ),
        ),
      ),
    );
  }
}
