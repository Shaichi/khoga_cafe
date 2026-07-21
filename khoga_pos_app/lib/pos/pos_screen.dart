import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/customer_api.dart';
import '../api/menu_api.dart';
import '../api/models.dart';
import '../api/voucher_api.dart';
import '../auth/auth_controller.dart';
import '../format.dart';
import '../theme.dart';
import '../orders/order_history_screen.dart';
import 'cart_controller.dart';
import 'close_shift_screen.dart';
import 'payment_screen.dart';
import 'shift_controller.dart';

/// Screen 35 — "POS Checkout Grid & Cart". Lists menu items (category tabs +
/// search) and builds a local cart. Voucher/loyalty/payment land in slice F5.
class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  late final MenuApi _menuApi;
  late final CustomerApi _customerApi;
  late final VoucherApi _voucherApi;
  final _searchCtrl = TextEditingController();

  List<Category> _categories = [];
  List<MenuItem> _items = [];
  String? _selectedCategoryId; // null = all
  String _search = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _menuApi = MenuApi(context.read<ApiClient>());
    _customerApi = CustomerApi(context.read<ApiClient>());
    _voucherApi = VoucherApi(context.read<ApiClient>());
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cats = await _menuApi.listCategories();
      final items = await _menuApi.listMenuItems();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _items = items;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Không tải được thực đơn');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<MenuItem> get _filtered {
    return _items.where((it) {
      final byCat = _selectedCategoryId == null || it.categoryId == _selectedCategoryId;
      final q = _search.toLowerCase();
      final bySearch = _search.isEmpty || 
          it.name.toLowerCase().contains(q) ||
          (it.abbreviation?.toLowerCase().contains(q) ?? false) ||
          (it.barcode?.contains(_search) ?? false);
      return byCat && bySearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final register = context.watch<ShiftController>().active?.posRegisterId ?? '—';
    final cashier = context.watch<AuthController>().profile?.username ?? '—';

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(register, cashier),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                key: const Key('pos-search'),
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
                decoration: const InputDecoration(
                  hintText: 'Quét mã vạch hoặc tìm kiếm…',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            _categoryChips(),
            Expanded(child: _itemList()),
            _cartPanel(cart),
          ],
        ),
      ),
    );
  }

  Widget _topBar(String register, String cashier) => Container(
        width: double.infinity,
        color: kBrown,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text('Máy: $register  ·  TN: $cashier',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const OrderHistoryScreen()),
              ),
              child: const Text('Lịch sử đơn', style: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const CloseShiftScreen()),
              ),
              child: const Text('Đóng ca', style: TextStyle(color: kGold, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

  Widget _categoryChips() {
    final chips = <Widget>[
      _chip('Tất cả', _selectedCategoryId == null, () => setState(() => _selectedCategoryId = null)),
      for (final c in _categories)
        _chip(c.name, _selectedCategoryId == c.id, () => setState(() => _selectedCategoryId = c.id)),
    ];
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: chips,
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          selectedColor: kBrown,
          labelStyle: TextStyle(color: selected ? Colors.white : kBrown, fontWeight: FontWeight.w600),
        ),
      );

  Widget _itemList() {
    if (_loading) return const Center(child: Text('Đang tải thực đơn…'));
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: kDanger)));
    final items = _filtered;
    if (items.isEmpty) return const Center(child: Text('Không có món phù hợp'));

    final groups = <String, List<MenuItem>>{};
    final standalone = <MenuItem>[];
    for (final it in items) {
      if (it.parentItemId != null) {
        groups.putIfAbsent(it.parentItemId!, () => []).add(it);
      } else {
        standalone.add(it);
      }
    }

    final groupList = groups.values.toList();
    final itemCount = standalone.length + groupList.length;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const Divider(height: 1, color: kBorder),
      itemBuilder: (_, i) {
        if (i < standalone.length) {
          final it = standalone[i];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(it.name, style: const TextStyle(fontWeight: FontWeight.w600, color: kBrown)),
            subtitle: Text('${formatVnd(it.price)} đ', style: const TextStyle(color: kMuted)),
            trailing: IconButton(
              key: Key('add-${it.id}'),
              icon: const CircleAvatar(backgroundColor: kGold, child: Icon(Icons.add, color: Colors.white, size: 20)),
              onPressed: () => _showItemOptionsDialog(it),
            ),
          );
        } else {
          final group = groupList[i - standalone.length];
          group.sort((a, b) => a.price.compareTo(b.price));
          final minPrice = group.first.price;
          final maxPrice = group.last.price;
          final priceStr = minPrice == maxPrice ? '${formatVnd(minPrice)} đ' : '${formatVnd(minPrice)} đ - ${formatVnd(maxPrice)} đ';
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(group.first.name, style: const TextStyle(fontWeight: FontWeight.w600, color: kBrown)),
            subtitle: Text(priceStr, style: const TextStyle(color: kMuted)),
            trailing: IconButton(
              key: Key('group-add-${group.first.parentItemId}'),
              icon: const CircleAvatar(backgroundColor: kGold, child: Icon(Icons.add, color: Colors.white, size: 20)),
              onPressed: () => _showSizeSelectionDialog(group),
            ),
          );
        }
      },
    );
  }

  Widget _cartPanel(CartController cart) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: kBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Giỏ Hàng Thanh Toán', style: TextStyle(fontWeight: FontWeight.bold, color: kBrown)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'TAKEAWAY', label: Text('Mang đi')),
              ButtonSegment(value: 'DINE_IN', label: Text('Tại quán')),
            ],
            selected: {cart.orderType},
            onSelectionChanged: (v) => cart.setOrderType(v.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: kBrown.withOpacity(0.1),
              selectedForegroundColor: kBrown,
            ),
          ),
          const SizedBox(height: 8),
          if (cart.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text('Giỏ hàng trống. Chọn sản phẩm bên trên để thêm vào hóa đơn.',
                  style: TextStyle(color: kMuted)),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: ListView(
                shrinkWrap: true,
                children: [for (final l in cart.lines) _cartLine(cart, l)],
              ),
            ),
          const Divider(),
          _totalRow('Tổng tiền hàng (Tạm tính)', '${formatVnd(cart.subtotal)} đ', key: const Key('cart-subtotal')),
          if (cart.voucherDiscount > 0)
            _totalRow('Chiết khấu (Voucher/Hội viên)', '-${formatVnd(cart.voucherDiscount)} đ', key: const Key('cart-discount'), color: kDanger),
          if (cart.pointDiscount > 0)
            _totalRow('Đổi điểm tích lũy', '-${formatVnd(cart.pointDiscount)} đ', key: const Key('cart-points-discount'), color: kDanger),
          _totalRow('Thuế VAT (10% đã gồm trong giá)', '${formatVnd((cart.netTotal * 10 / 110).round())} đ',
              color: kMuted, fontSize: 11),
          _totalRow('Tổng cộng cần trả (Net)', '${formatVnd(cart.netTotal)} đ', bold: true),
          _appliedSection(cart),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('member-button'),
                  onPressed: cart.isEmpty ? null : _openMemberSheet,
                  child: Text(cart.customer == null ? 'HỘI VIÊN' : 'ĐỔI HV', textAlign: TextAlign.center),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  key: const Key('voucher-button'),
                  onPressed: cart.isEmpty ? null : _openPromoDialog,
                  child: Text(cart.voucherCode == null && cart.redeemPoints == 0 ? 'KHUYẾN MÃI' : 'ĐỔI MÃ/ĐIỂM', textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            key: const Key('checkout-button'),
            onPressed: cart.isEmpty
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const PaymentScreen()),
                    ),
            child: const Text('THANH TOÁN'),
          ),
        ],
      ),
    );
  }

  /// Shows the attached member (with an optional points-to-redeem field) and the
  /// applied voucher code, each removable. Hidden when nothing is applied.
  Widget _appliedSection(CartController cart) {
    final member = cart.customer;
    final voucher = cart.voucherCode;
    if (member == null && voucher == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (member != null)
            Row(
              key: const Key('member-chip'),
              children: [
                const Icon(Icons.card_membership, size: 18, color: kBrown),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('${member.fullName} · ${formatVnd(member.points)}đ',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: kBrown)),
                ),
                if (member.points > 0 && cart.redeemPoints > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFFDECEB), borderRadius: BorderRadius.circular(4)),
                    child: Text('Đổi: ${cart.redeemPoints} điểm', style: const TextStyle(fontSize: 12, color: kDanger, fontWeight: FontWeight.bold)),
                  ),
                IconButton(
                  key: const Key('member-remove'),
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: cart.clearCustomer,
                ),
              ],
            ),
          if (voucher != null)
            Row(
              key: const Key('voucher-chip'),
              children: [
                const Icon(Icons.local_offer, size: 18, color: kBrown),
                const SizedBox(width: 6),
                Expanded(child: Text('Mã: $voucher', style: const TextStyle(fontWeight: FontWeight.w600, color: kBrown))),
                IconButton(
                  key: const Key('voucher-remove'),
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: cart.clearVoucher,
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// UC-48: look up a member by name/phone and attach them to the order.
  Future<void> _openMemberSheet() async {
    final cart = context.read<CartController>();
    final picked = await showModalBottomSheet<CustomerLite>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        String query = '';
        List<CustomerLite> results = [];
        String? error;
        bool loading = false;
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            Future<void> run(String q) async {
              query = q;
              if (q.trim().isEmpty) {
                setSheet(() {
                  results = [];
                  error = null;
                });
                return;
              }
              setSheet(() => loading = true);
              try {
                final r = await _customerApi.search(q.trim());
                setSheet(() {
                  results = r;
                  error = null;
                });
              } catch (e) {
                setSheet(() => error = e is ApiException ? e.message : 'Không tìm được khách hàng');
              } finally {
                setSheet(() => loading = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Tìm hội viên', style: TextStyle(fontWeight: FontWeight.bold, color: kBrown)),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('member-search'),
                    autofocus: true,
                    decoration: const InputDecoration(hintText: 'Tên hoặc số điện thoại…', prefixIcon: Icon(Icons.search)),
                    onChanged: run,
                  ),
                  const SizedBox(height: 8),
                  if (loading) const Padding(padding: EdgeInsets.all(8), child: Text('Đang tìm…')),
                  if (error != null) Text(error!, style: const TextStyle(color: kDanger)),
                  if (!loading && error == null && query.trim().isNotEmpty && results.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Không tìm thấy hội viên'),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.person_add),
                            label: const Text('Thêm hội viên mới'),
                            onPressed: () async {
                              final nameCtrl = TextEditingController();
                              final phoneCtrl = TextEditingController();
                              final emailCtrl = TextEditingController();
                              if (RegExp(r'^\d+$').hasMatch(query)) {
                                phoneCtrl.text = query;
                              } else {
                                nameCtrl.text = query;
                              }
                              final newCustomer = await showDialog<CustomerLite>(
                                context: ctx,
                                builder: (dialogCtx) => AlertDialog(
                                  title: const Text('Thêm hội viên mới'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Họ tên *')),
                                      const SizedBox(height: 8),
                                      TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Số điện thoại *'), keyboardType: TextInputType.phone),
                                      const SizedBox(height: 8),
                                      TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email (Tùy chọn)'), keyboardType: TextInputType.emailAddress),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Hủy')),
                                    ElevatedButton(
                                      onPressed: () async {
                                        try {
                                          final c = await _customerApi.create(nameCtrl.text, phoneCtrl.text, email: emailCtrl.text.trim());
                                          if (ctx.mounted) Navigator.pop(dialogCtx, c);
                                        } catch (e) {
                                          if (ctx.mounted) {
                                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'Lỗi')));
                                          }
                                        }
                                      },
                                      child: const Text('Thêm'),
                                    ),
                                  ],
                                ),
                              );
                              if (newCustomer != null && ctx.mounted) {
                                Navigator.pop(ctx, newCustomer);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final c in results)
                          ListTile(
                            key: Key('member-result-${c.id}'),
                            title: Text(c.fullName),
                            subtitle: Text('${c.phone ?? '—'} · ${formatVnd(c.points)} điểm'),
                            onTap: () => Navigator.of(ctx).pop(c),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (picked != null) cart.attachCustomer(picked);
  }

  /// UC-48: Promo dialog containing both Voucher selection and Points redemption
  Future<void> _openPromoDialog() async {
    final cart = context.read<CartController>();
    await showDialog(
      context: context,
      builder: (ctx) => PromoDialog(
        cart: cart,
        voucherApi: _voucherApi,
      ),
    );
  }

  Widget _cartLine(CartController cart, CartLine l) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(l.item.sizeName != null ? '${l.item.name} (Size ${l.item.sizeName})' : l.item.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                IconButton(
                  key: Key('dec-${l.id}'),
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  onPressed: () async {
                    if (l.qty == 1) {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Xóa món'),
                          content: Text('Bạn muốn xóa ${l.item.name} khỏi giỏ?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('HỦY')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: kDanger),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('XÓA'),
                            ),
                          ],
                        ),
                      );
                      if (confirm != true) return;
                    }
                    cart.decrementByLineId(l.id);
                  },
                ),
                Text('${l.qty}', style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  key: Key('inc-${l.id}'),
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: () => cart.addByLineId(l.id),
                ),
                SizedBox(width: 88, child: Text('${formatVnd(l.lineTotal)} đ', textAlign: TextAlign.right)),
              ],
            ),
            if (l.toppings.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Text(
                  l.toppings.map((t) => '${t.qty}x ${t.name}').join(', '),
                  style: const TextStyle(fontSize: 12, color: kMuted),
                ),
              ),
          ],
        ),
      );

  Widget _totalRow(String label, String value, {bool bold = false, Key? key, Color? color, double? fontSize}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: color ?? (bold ? kBrown : kMuted), fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize)),
            Text(value, key: key, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w600, color: color ?? kBrown, fontSize: fontSize)),
          ],
        ),
      );

  Future<void> _showItemOptionsDialog(MenuItem item) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final toppings = await _menuApi.listToppings(item.id);
      if (!mounted) return;
      Navigator.pop(context); // close loading
      
      if (toppings.isEmpty) {
        context.read<CartController>().add(item);
        return;
      }
      
      final selectedToppings = <String, CartTopping>{};
      
      await showDialog(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setDialogState) {
              return AlertDialog(
                title: Text('Tuỳ chọn cho ${item.name}'),
                content: SizedBox(
                  width: 400,
                  child: ListView(
                    shrinkWrap: true,
                    children: toppings.map((t) {
                      final currentQty = selectedToppings[t.id]?.qty ?? 0;
                      return ListTile(
                        title: Text(t.name),
                        subtitle: Text('+${formatVnd(t.price)} đ'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: currentQty == 0 ? null : () {
                                setDialogState(() {
                                  if (currentQty > 1) {
                                    selectedToppings[t.id]!.qty--;
                                  } else {
                                    selectedToppings.remove(t.id);
                                  }
                                });
                              },
                            ),
                            Text('$currentQty', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                setDialogState(() {
                                  if (currentQty == 0) {
                                    selectedToppings[t.id] = CartTopping(id: t.id, name: t.name, price: t.price, qty: 1);
                                  } else {
                                    selectedToppings[t.id]!.qty++;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                  ElevatedButton(
                    onPressed: () {
                      context.read<CartController>().add(item, toppings: selectedToppings.values.toList());
                      Navigator.pop(ctx);
                    },
                    child: const Text('Thêm vào giỏ'),
                  ),
                ],
              );
            }
          );
        }
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close loading
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi tải tuỳ chọn')));
    }
  }

  Future<void> _showSizeSelectionDialog(List<MenuItem> variants) async {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Chọn Size cho ${variants.first.name}'),
          content: SizedBox(
            width: 300,
            child: ListView(
              shrinkWrap: true,
              children: variants.map((v) {
                return ListTile(
                  title: Text('Size ${v.sizeName ?? ""}'),
                  trailing: Text('${formatVnd(v.price)} đ'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showItemOptionsDialog(v);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ],
        );
      },
    );
  }
}

class PromoDialog extends StatefulWidget {
  final CartController cart;
  final VoucherApi voucherApi;

  const PromoDialog({super.key, required this.cart, required this.voucherApi});

  @override
  State<PromoDialog> createState() => _PromoDialogState();
}

class _PromoDialogState extends State<PromoDialog> {
  late TextEditingController _voucherCtrl;
  late TextEditingController _pointsCtrl;
  List<VoucherLite>? _activeVouchers;

  @override
  void initState() {
    super.initState();
    _voucherCtrl = TextEditingController(text: widget.cart.voucher?.code ?? '');
    _pointsCtrl = TextEditingController(text: widget.cart.redeemPoints > 0 ? widget.cart.redeemPoints.toString() : '');
    
    widget.voucherApi.listActive().then((list) {
      if (mounted) setState(() => _activeVouchers = list);
    }).catchError((_) {
      if (mounted) setState(() => _activeVouchers = []);
    });
  }

  @override
  void dispose() {
    _voucherCtrl.dispose();
    _pointsCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    // 1. Handle points
    final pointsText = _pointsCtrl.text.trim();
    if (pointsText.isNotEmpty) {
      final points = int.tryParse(pointsText) ?? 0;
      widget.cart.setRedeemPoints(points);
    } else {
      widget.cart.setRedeemPoints(0);
    }

    // 2. Handle voucher
    final code = _voucherCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      widget.cart.clearVoucher();
      Navigator.of(context).pop();
      return;
    }

    final matched = _activeVouchers?.where((v) => v.code == code).firstOrNull;
    if (matched != null) {
      widget.cart.applyVoucher(matched);
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mã voucher không hợp lệ hoặc chưa hỗ trợ lookup')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxPoints = widget.cart.customer?.points ?? 0;
    final hasMember = widget.cart.customer != null;

    return AlertDialog(
      title: const Text('Voucher & Đổi Điểm Tích Lũy'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Voucher section
              const Text('Mã khuyến mãi', style: TextStyle(fontWeight: FontWeight.bold, color: kBrown)),
              const SizedBox(height: 8),
              TextField(
                key: const Key('voucher-input'),
                controller: _voucherCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'Nhập mã (vd: GIOVANG)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              if (_activeVouchers == null)
                const Center(child: CircularProgressIndicator())
              else if (_activeVouchers!.isNotEmpty) ...[
                const Text('Chọn mã khả dụng:', style: TextStyle(fontSize: 12, color: kMuted)),
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: ListView(
                    shrinkWrap: true,
                    children: _activeVouchers!.map((v) {
                      return ListTile(
                        dense: true,
                        title: Text(v.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(v.description ?? '${v.discountValue} ${v.discountType == "PERCENTAGE" ? "%" : "VND"}'),
                        onTap: () => setState(() => _voucherCtrl.text = v.code),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const Divider(height: 32),

              // Points section
              const Text('Đổi điểm tích lũy', style: TextStyle(fontWeight: FontWeight.bold, color: kBrown)),
              const SizedBox(height: 4),
              if (!hasMember)
                const Text('Vui lòng gắn hội viên vào đơn hàng để đổi điểm.', style: TextStyle(fontSize: 13, color: kDanger))
              else ...[
                Text('Khả dụng: $maxPoints điểm (1 điểm = 100đ)', style: const TextStyle(fontSize: 13, color: kMuted)),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('redeem-points-input'),
                  controller: _pointsCtrl,
                  keyboardType: TextInputType.number,
                  enabled: maxPoints > 0,
                  decoration: const InputDecoration(
                    hintText: 'Nhập số điểm cần đổi',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('HỦY')),
        ElevatedButton(
          key: const Key('promo-apply'),
          onPressed: _apply,
          child: const Text('XÁC NHẬN'),
        ),
      ],
    );
  }
}
