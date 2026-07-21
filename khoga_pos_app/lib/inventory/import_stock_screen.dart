import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/stock_api.dart';
import '../format.dart';
import '../theme.dart';

// Figma Colors
const Color cBgWhite = Color(0xFFFFFFFF);
const Color cBorderLight = Color(0xFFEADDD3);
const Color cTextDark = Color(0xFF2C1A11);
const Color cTextMuted = Color(0xFF8C766C);
const Color cBrownDark = Color(0xFF3D2314);
const Color cPrimary = Color(0xFF5C3826);
const Color cTextLightBrown = Color(0xFF8C6D58);
const Color cHighlight = Color(0xFFC89D7C);
const Color cDanger = Color(0xFFCF6679);
const Color cBgDisabled = Color(0xFFFDFDFD);

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashWidth;
  final double dashSpace;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.radius = 20.0,
    this.dashWidth = 5.0,
    this.dashSpace = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius)));

    Path dashPath = Path();
    double distance = 0.0;
    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth;
        distance += dashSpace;
      }
      distance = 0.0;
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ImportStockItemModel {
  StockItem? stockItem;
  final TextEditingController qtyController = TextEditingController(text: '0.0');
  final TextEditingController priceController = TextEditingController(text: '0');
  String? error;

  void dispose() {
    qtyController.dispose();
    priceController.dispose();
  }

  num get total => (num.tryParse(qtyController.text) ?? 0) * (num.tryParse(priceController.text) ?? 0);
}

class ImportStockScreen extends StatefulWidget {
  const ImportStockScreen({super.key});

  @override
  State<ImportStockScreen> createState() => _ImportStockScreenState();
}

class _ImportStockScreenState extends State<ImportStockScreen> {
  late final StockApi _api;
  
  List<StockItem> _availableItems = [];
  bool _loadingItems = true;
  String? _globalError;
  bool _submitting = false;
  
  final List<ImportStockItemModel> _importList = [];
  
  String? _selectedSupplier;
  final TextEditingController _noteController = TextEditingController();

  final List<String> _dummySuppliers = [
    'Highlands Supplier',
    'Trung Nguyên',
    'Nhà cung cấp nội bộ',
    'Khác'
  ];
  
  bool _success = false;
  int _successCount = 0;

  @override
  void initState() {
    super.initState();
    _api = StockApi(context.read<ApiClient>());
    _loadItems();
    _importList.add(ImportStockItemModel());
  }

  Future<void> _loadItems() async {
    try {
      final list = await _api.list();
      if (mounted) {
        setState(() {
          _availableItems = list;
          _loadingItems = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _globalError = 'Không tải được danh sách nguyên liệu';
          _loadingItems = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (var item in _importList) {
      item.dispose();
    }
    _noteController.dispose();
    super.dispose();
  }

  void _addRow() {
    setState(() {
      _importList.add(ImportStockItemModel());
    });
  }

  void _removeItem(int index) {
    setState(() {
      final item = _importList.removeAt(index);
      item.dispose();
    });
  }

  num _calculateGrandTotal() {
    num total = 0;
    for (var item in _importList) {
      total += item.total;
    }
    return total;
  }

  Future<void> _submit() async {
    if (_selectedSupplier == null) {
      setState(() => _globalError = 'Vui lòng chọn nhà cung cấp');
      return;
    }

    final validItems = _importList.where((i) => i.stockItem != null).toList();
    if (validItems.isEmpty) {
      setState(() => _globalError = 'Vui lòng chọn ít nhất 1 nguyên liệu để nhập');
      return;
    }

    bool hasValidationErrors = false;
    for (var item in validItems) {
      final qty = num.tryParse(item.qtyController.text.trim());
      if (qty == null || qty <= 0) {
        item.error = 'Số lượng không hợp lệ';
        hasValidationErrors = true;
      } else {
        item.error = null;
      }
    }

    if (hasValidationErrors) {
      setState(() {});
      return;
    }

    setState(() {
      _globalError = null;
      _submitting = true;
    });

    try {
      final combinedNote = 'NCC: $_selectedSupplier\n${_noteController.text.trim()}';
      
      final futures = validItems.map((item) async {
        final qty = num.parse(item.qtyController.text.trim());
        return _api.import(item.stockItem!.id, qty, note: combinedNote);
      });
      
      await Future.wait(futures);
      
      if (mounted) {
        setState(() {
          _successCount = validItems.length;
          _success = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _globalError = e is ApiException ? e.message : 'Có lỗi xảy ra khi nhập kho');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBgWhite,
      appBar: AppBar(
        backgroundColor: cBgWhite,
        foregroundColor: cBrownDark,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: cBrownDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Nhập Kho',
          style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 22, color: cBrownDark),
        ),
      ),
      body: SafeArea(
        child: _success ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  Widget _buildSuccess() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: kSuccess, size: 64),
            const SizedBox(height: 12),
            const Text('Nhập kho thành công', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cPrimary)),
            const SizedBox(height: 8),
            Text('Đã nhập thành công $_successCount mặt hàng', style: const TextStyle(color: cTextMuted)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: cPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('XONG'),
            ),
          ],
        ),
      );

  Widget _buildForm() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_globalError != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: cDanger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cDanger),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: cDanger),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_globalError!, style: const TextStyle(color: cDanger, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),

                // Nhà cung cấp
                const Text('Nhà cung cấp *', style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, color: cBrownDark, fontSize: 15)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: Highlands Supplier',
                    hintStyle: const TextStyle(color: cTextMuted),
                    filled: true,
                    fillColor: cBgWhite,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: cBorderLight)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: cBorderLight)),
                  ),
                  value: _selectedSupplier,
                  items: _dummySuppliers.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _selectedSupplier = v),
                ),
                const SizedBox(height: 20),

                // Ghi chú phiếu nhập
                const Text('Ghi chú phiếu nhập', style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, color: cBrownDark, fontSize: 15)),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Nhập ghi chú chi tiết nếu có...',
                    hintStyle: const TextStyle(color: cTextMuted),
                    filled: true,
                    fillColor: cBgWhite,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: cBorderLight)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: cBorderLight)),
                  ),
                ),
                const SizedBox(height: 24),

                // Danh sách nhập kho header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Danh sách nhập kho', style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, color: cBrownDark, fontSize: 16)),
                    InkWell(
                      onTap: _addRow,
                      borderRadius: BorderRadius.circular(20),
                      child: CustomPaint(
                        painter: DashedBorderPainter(color: cHighlight, radius: 20, strokeWidth: 1.2),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 16, color: cTextLightBrown),
                              SizedBox(width: 4),
                              Text('Thêm dòng', style: TextStyle(color: cTextLightBrown, fontSize: 13, fontFamily: 'Segoe UI')),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: cBgDisabled), // Very light divider
                const SizedBox(height: 16),

                // List items
                ..._importList.asMap().entries.map((e) {
                  final index = e.key;
                  final itemModel = e.value;
                  return _buildItemCard(index, itemModel);
                }),
                
                const SizedBox(height: 8),

                // TỔNG TIỀN HÀNG
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: cBgWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cBorderLight),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TỔNG TIỀN HÀNG:', style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, color: cBrownDark, fontSize: 15)),
                      Text('${formatVnd(_calculateGrandTotal())} VND', style: const TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, color: cBrownDark, fontSize: 18)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Footer buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: cBgWhite,
            border: Border(top: BorderSide(color: cBorderLight)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    side: const BorderSide(color: cBorderLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('HỦY', style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, color: cBrownDark)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    minimumSize: const Size(0, 50),
                    backgroundColor: cBrownDark, // Use the darker brown for confirm button based on image (looks dark)
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _submitting
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('XÁC NHẬN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Segoe UI')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(int index, ImportStockItemModel itemModel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cBgWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _loadingItems
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<StockItem>(
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: cBorderLight)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: cBorderLight)),
                        ),
                        isExpanded: true,
                        value: itemModel.stockItem,
                        items: _availableItems.map((item) {
                          return DropdownMenuItem<StockItem>(
                            value: item,
                            child: Text(item.name, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            itemModel.stockItem = val;
                            if (val != null) {
                              itemModel.priceController.text = val.standardCost.toString();
                            }
                          });
                        },
                      ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, color: cDanger, size: 20),
                onPressed: () => _removeItem(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Số lượng *', style: TextStyle(fontSize: 12, color: cTextMuted, fontWeight: FontWeight.bold, fontFamily: 'Segoe UI')),
                    const SizedBox(height: 8),
                    TextField(
                      controller: itemModel.qtyController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        errorText: itemModel.error,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: cBorderLight)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: cBorderLight)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Đơn giá (VND) *', style: TextStyle(fontSize: 12, color: cTextMuted, fontWeight: FontWeight.bold, fontFamily: 'Segoe UI')),
                    const SizedBox(height: 8),
                    TextField(
                      controller: itemModel.priceController,
                      readOnly: true, // Lấy từ config admin
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: cBorderLight)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: cBorderLight)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Thành tiền', style: TextStyle(fontSize: 12, color: cTextMuted, fontWeight: FontWeight.bold, fontFamily: 'Segoe UI')),
                    const SizedBox(height: 20), 
                    Text(
                      '${formatVnd(itemModel.total)} VND',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Segoe UI', color: cTextDark, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
