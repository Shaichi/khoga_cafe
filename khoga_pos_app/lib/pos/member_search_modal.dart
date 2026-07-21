import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_client.dart';
import '../api/customer_api.dart';
import '../api/models.dart';
import '../format.dart';
import '../theme.dart';
import 'points_modal.dart';
import 'cart_controller.dart';

class MemberSearchModal extends StatefulWidget {
  final CustomerApi customerApi;
  final CartController cart;

  const MemberSearchModal({super.key, required this.customerApi, required this.cart});

  @override
  State<MemberSearchModal> createState() => _MemberSearchModalState();
}

class _MemberSearchModalState extends State<MemberSearchModal> {
  final _searchCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  CustomerLite? _foundCustomer;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _foundCustomer = null;
    });

    try {
      final results = await widget.customerApi.search(q);
      setState(() {
        if (results.isEmpty) {
          _error = 'Không tìm thấy hội viên';
        } else {
          _foundCustomer = results.first; // Pick the first match
        }
      });
    } catch (e) {
      setState(() {
        _error = e is ApiException ? e.message : 'Lỗi khi tìm kiếm';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _openPointsModal() {
    // Before opening points modal, we should probably close this one.
    // Wait, the flow is: attach member -> open points modal?
    // Or just open points modal and pass the found member directly?
    // The requirement says: click "Xem trang riêng" -> open points modal.
    // If they haven't attached yet, we should attach first or just pass to points modal.
    // Let's attach the found customer first.
    if (_foundCustomer != null) {
      widget.cart.attachCustomer(_foundCustomer!);
      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (ctx) => PointsModal(cart: widget.cart),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340), // slightly smaller than 375 based on Figma 310px width
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tìm Kiếm Hội Viên',
                    style: TextStyle(
                      fontFamily: 'Segoe UI',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF2C1A11),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text(
                      '×',
                      style: TextStyle(
                        fontFamily: 'Arial',
                        fontSize: 20,
                        color: Color(0xFF8C766C),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFF0E6DF)),
              const SizedBox(height: 12),
              
              // Input
              const Text(
                'Số điện thoại hội viên',
                style: TextStyle(
                  fontFamily: 'Segoe UI',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF5C3826),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
                child: TextField(
                  key: const Key('member-search'),
                  controller: _searchCtrl,
                  autofocus: true,
                  onSubmitted: (_) => _search(),
                  style: const TextStyle(
                    fontFamily: 'Arial',
                    fontSize: 13,
                    color: Color(0xFF2C1A11),
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFEADDD3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: kGold, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Search button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D2314),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size.fromHeight(40),
                ),
                onPressed: _loading ? null : _search,
                child: _loading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text(
                      'TÌM KIẾM',
                      style: TextStyle(
                        fontFamily: 'Arial',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
              ),
              
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: kDanger, fontSize: 13), textAlign: TextAlign.center),
              ],
              
              if (_foundCustomer != null) ...[
                const SizedBox(height: 12),
                // Result box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFAF7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFC89D7C), style: BorderStyle.none),
                  ),
                  // Dashed border effect can be approximated with a CustomPaint or just solid if dashed is hard.
                  // For simplicity without external dashed border packages, we'll use a light solid border
                  // but we should technically try to match dashed. We will use a solid border for now to avoid custom painter complexity unless required.
                  // Actually, Flutter doesn't have a built-in dashed border. A solid border is usually acceptable as a fallback.
                  // Wait, let's just use a CustomPainter if we really want to match perfectly, but solid is probably fine.
                  // I'll stick to solid for now:
                  foregroundDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFC89D7C), width: 1), // Fallback to solid
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hội viên tìm thấy:',
                        style: TextStyle(
                          fontFamily: 'Segoe UI',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF5C3826),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(width: 80, child: Text('Tên:', style: TextStyle(fontFamily: 'Segoe UI', fontSize: 12, color: Color(0xFF5C3826)))),
                          Expanded(child: Text(_foundCustomer!.fullName, style: const TextStyle(fontFamily: 'Segoe UI', fontSize: 12, color: Color(0xFF5C3826)))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const SizedBox(width: 80, child: Text('Tích điểm:', style: TextStyle(fontFamily: 'Segoe UI', fontSize: 12, color: Color(0xFF5C3826)))),
                          Expanded(child: Text('${formatVnd(_foundCustomer!.points)} điểm', style: const TextStyle(fontFamily: 'Segoe UI', fontSize: 12, color: Color(0xFF5C3826)))),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 4),
                // Xem trang riêng
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: _openPointsModal,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Xem trang riêng',
                        style: TextStyle(
                          fontFamily: 'Segoe UI',
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Color(0xFFC89D7C),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFEADDD3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: const Size.fromHeight(38),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'BỎ QUA',
                        style: TextStyle(
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF3D2314),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3D2314),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: const Size.fromHeight(38),
                      ),
                      onPressed: _foundCustomer == null ? null : () {
                        widget.cart.attachCustomer(_foundCustomer!);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'GẮN HỘI VIÊN',
                        style: TextStyle(
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
