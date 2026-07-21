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
import '../profile/profile_screen.dart';
import 'cart_controller.dart';
import 'close_shift_screen.dart';
import 'member_search_modal.dart';
import 'payment_screen.dart';
import 'shift_controller.dart';
import 'voucher_modal.dart';

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
        _selectedCategoryId = cats.isEmpty ? null : cats.first.id;
      });
    } catch (e) {
      if (mounted)
        setState(
          () => _error = e is ApiException
              ? e.message
              : 'Không tải được thực đơn',
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<MenuItem> get _filtered {
    return _items.where((it) {
      final byCat =
          _selectedCategoryId == null || it.categoryId == _selectedCategoryId;
      final q = _search.toLowerCase();
      final bySearch =
          _search.isEmpty ||
          it.name.toLowerCase().contains(q) ||
          (it.abbreviation?.toLowerCase().contains(q) ?? false) ||
          (it.barcode?.contains(_search) ?? false);
      return byCat && bySearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final register =
        context.watch<ShiftController>().active?.posRegisterId ?? '—';
    final cashier = context.watch<AuthController>().profile?.username ?? '—';

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _topBar(register, cashier),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 36,
                    child: TextField(
                      key: const Key('pos-search'),
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _search = v),
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Quét mã vạch hoặc tìm kiếm...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 11),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _categoryChips(),
                  const SizedBox(height: 10),
                  SizedBox(height: 159, child: _itemList()),
                  const SizedBox(height: 10),
                  Expanded(child: _cartPanel(cart)),
                  const SizedBox(height: 8),
                  _actionBar(cart),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(String register, String cashier) => Container(
    height: 22,
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFF0E6DF))),
    ),
    child: Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            ),
            child: Text(
              'Máy: $register | TN: $cashier',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: kMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        InkWell(
          key: const Key('order-history-action'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const OrderHistoryScreen()),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Lịch sử đơn',
              style: TextStyle(
                color: kGold,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        InkWell(
          key: const Key('close-shift-action'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const CloseShiftScreen()),
          ),
          child: const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              'Đóng ca',
              style: TextStyle(
                color: kDanger,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _categoryChips() {
    final chips = _categories.take(3).toList();
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: _chip(
                chips[i].name,
                _selectedCategoryId == chips[i].id,
                () => setState(() => _selectedCategoryId = chips[i].id),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) =>
      OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 32),
          backgroundColor: selected ? kBrown : const Color(0xFFFDFDFD),
          foregroundColor: selected ? Colors.white : const Color(0xFF5C3826),
          side: BorderSide(color: selected ? kBrown : kBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      );

  Widget _itemList() {
    if (_loading) return const Center(child: Text('Đang tải thực đơn…'));
    if (_error != null)
      return Center(
        child: Text(_error!, style: const TextStyle(color: kDanger)),
      );
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
      padding: EdgeInsets.zero,
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        if (i < standalone.length) {
          final it = standalone[i];
          return _menuCard(
            name: it.name,
            price: '${formatVnd(it.price)} đ',
            buttonKey: Key('add-${it.id}'),
            onAdd: () => context.read<CartController>().add(it),
          );
        } else {
          final group = groupList[i - standalone.length];
          group.sort((a, b) => a.price.compareTo(b.price));
          final minPrice = group.first.price;
          final maxPrice = group.last.price;
          final priceStr = minPrice == maxPrice
              ? '${formatVnd(minPrice)} đ'
              : '${formatVnd(minPrice)} đ - ${formatVnd(maxPrice)} đ';
          return _menuCard(
            name: group.first.name,
            price: priceStr,
            buttonKey: Key('group-add-${group.first.parentItemId}'),
            onAdd: () => _showSizeSelectionDialog(group),
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
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Giỏ Hàng Thanh Toán',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: kMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 18),
          if (cart.isEmpty)
            const Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  'Giỏ hàng trống. Chọn sản phẩm bên trên để thêm vào hóa đơn.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kMuted, fontSize: 12),
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                children: [for (final l in cart.lines) _cartLine(cart, l)],
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFDFaf7),
              border: Border.all(color: kBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _totalRow(
                  'Tổng tiền hàng (Tạm tính)',
                  '${formatVnd(cart.subtotal)} đ',
                  key: const Key('cart-subtotal'),
                ),
                _totalRow(
                  'Chiết khấu (Voucher/Hội viên)',
                  '-${formatVnd(cart.voucherDiscount)} đ',
                ),
                _totalRow(
                  'Đổi điểm tích lũy',
                  '-${formatVnd(cart.pointDiscount)} đ',
                ),
                _totalRow(
                  'Thuế VAT (10% đã gồm trong giá)',
                  '${formatVnd((cart.netTotal * 10 / 110).round())} đ',
                  color: kMuted,
                  fontSize: 11,
                ),
                const Divider(height: 12, color: kBorder),
                _totalRow(
                  'Tổng cộng cần trả (Net)',
                  '${formatVnd(cart.netTotal)} đ',
                  bold: true,
                ),
              ],
            ),
          ),
          _appliedSection(cart),
        ],
      ),
    );
  }

  Widget _menuCard({
    required String name,
    required String price,
    required Key buttonKey,
    required VoidCallback onAdd,
  }) => Container(
    constraints: const BoxConstraints(minHeight: 52),
    padding: const EdgeInsets.fromLTRB(12, 6, 10, 6),
    decoration: BoxDecoration(
      color: const Color(0xFFFAFAFA),
      border: Border.all(color: const Color(0xFFEEEEEE)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C1A11),
                ),
              ),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: kMuted,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 28,
          height: 28,
          child: IconButton(
            key: buttonKey,
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              backgroundColor: kGold,
              foregroundColor: Colors.white,
            ),
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
          ),
        ),
      ],
    ),
  );

  Widget _actionBar(CartController cart) => SizedBox(
    height: 40,
    child: Row(
      children: [
        Expanded(
          flex: 5,
          child: OutlinedButton(
            key: const Key('member-button'),
            onPressed: cart.isEmpty ? null : _openMemberSheet,
            style: _footerOutlineStyle(),
            child: Text(cart.customer == null ? 'HỘI VIÊN' : 'ĐỔI HV'),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 5,
          child: OutlinedButton(
            key: const Key('voucher-button'),
            onPressed: cart.isEmpty ? null : _openVoucherModal,
            style: _footerOutlineStyle(),
            child: const Text('KHUYẾN MÃI'),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 6,
          child: ElevatedButton(
            key: const Key('checkout-button'),
            onPressed: cart.isEmpty
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PaymentScreen(),
                    ),
                  ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('THANH TOÁN'),
          ),
        ),
      ],
    ),
  );

  ButtonStyle _footerOutlineStyle() => OutlinedButton.styleFrom(
    minimumSize: const Size(0, 40),
    padding: EdgeInsets.zero,
    foregroundColor: kBrown,
    side: const BorderSide(color: kBorder),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
  );

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
                  child: Text(
                    '${member.fullName} · ${formatVnd(member.points)}đ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: kBrown,
                    ),
                  ),
                ),
                if (member.points > 0 && cart.redeemPoints > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDECEB),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Đổi: ${cart.redeemPoints} điểm',
                      style: const TextStyle(
                        fontSize: 12,
                        color: kDanger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                Expanded(
                  child: Text(
                    'Mã: $voucher',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: kBrown,
                    ),
                  ),
                ),
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
  void _openMemberSheet() {
    showDialog<void>(
      context: context,
      builder: (ctx) => MemberSearchModal(
        customerApi: _customerApi,
        cart: context.read<CartController>(),
      ),
    );
  }

  void _openVoucherModal() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) => VoucherModal(
          cart: context.read<CartController>(),
          voucherApi: _voucherApi,
        ),
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
            Expanded(
              child: Text(
                l.item.sizeName != null
                    ? '${l.item.name} (Size ${l.item.sizeName})'
                    : l.item.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
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
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('HỦY'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kDanger,
                          ),
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
            Text(
              '${l.qty}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              key: Key('inc-${l.id}'),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              onPressed: () => cart.addByLineId(l.id),
            ),
            SizedBox(
              width: 88,
              child: Text(
                '${formatVnd(l.lineTotal)} đ',
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _totalRow(
    String label,
    String value, {
    bool bold = false,
    Key? key,
    Color? color,
    double? fontSize,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color ?? (bold ? kBrown : kMuted),
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontSize: fontSize,
          ),
        ),
        Text(
          value,
          key: key,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: color ?? kBrown,
            fontSize: fontSize,
          ),
        ),
      ],
    ),
  );

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
                    context.read<CartController>().add(v);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
          ],
        );
      },
    );
  }
}
