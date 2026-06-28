import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/menu_api.dart';
import '../api/models.dart';
import '../auth/auth_controller.dart';
import '../format.dart';
import '../theme.dart';
import 'cart_controller.dart';
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
      final bySearch = _search.isEmpty || it.name.toLowerCase().contains(_search.toLowerCase());
      return byCat && bySearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final register = context.watch<ShiftController>().active?.posRegisterId ?? '—';
    final cashier = context.watch<AuthController>().profile?.username ?? '—';

    return Scaffold(
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
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đóng ca — sắp có')),
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
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1, color: kBorder),
      itemBuilder: (_, i) {
        final it = items[i];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(it.name, style: const TextStyle(fontWeight: FontWeight.w600, color: kBrown)),
          subtitle: Text('${formatVnd(it.price)} đ', style: const TextStyle(color: kMuted)),
          trailing: IconButton(
            key: Key('add-${it.id}'),
            icon: const CircleAvatar(backgroundColor: kGold, child: Icon(Icons.add, color: Colors.white, size: 20)),
            onPressed: () => context.read<CartController>().add(it),
          ),
        );
      },
    );
  }

  Widget _cartPanel(CartController cart) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: kBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Giỏ Hàng Thanh Toán', style: TextStyle(fontWeight: FontWeight.bold, color: kBrown)),
          const SizedBox(height: 8),
          if (cart.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
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
          _totalRow('Tổng cộng cần trả (Net)', '${formatVnd(cart.subtotal)} đ', bold: true),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: cart.isEmpty ? null : () {}, child: const Text('HỘI VIÊN')),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(onPressed: cart.isEmpty ? null : () {}, child: const Text('KHUYẾN MÃI')),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  key: const Key('checkout-button'),
                  onPressed: cart.isEmpty
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const PaymentScreen()),
                          ),
                  child: const Text('THANH TOÁN'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cartLine(CartController cart, CartLine l) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(l.item.name, style: const TextStyle(fontWeight: FontWeight.w600))),
            IconButton(
              key: Key('dec-${l.item.id}'),
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              onPressed: () => cart.decrement(l.item.id),
            ),
            Text('${l.qty}', style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              key: Key('inc-${l.item.id}'),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              onPressed: () => cart.add(l.item),
            ),
            SizedBox(width: 88, child: Text('${formatVnd(l.lineTotal)} đ', textAlign: TextAlign.right)),
          ],
        ),
      );

  Widget _totalRow(String label, String value, {bool bold = false, Key? key}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: bold ? kBrown : kMuted, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
            Text(value, key: key, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w600, color: kBrown)),
          ],
        ),
      );
}
