import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/stock_api.dart';
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

class ExportStockScreen extends StatefulWidget {
  const ExportStockScreen({super.key});

  @override
  State<ExportStockScreen> createState() => _ExportStockScreenState();
}

class _ExportStockScreenState extends State<ExportStockScreen> {
  late final StockApi _api;
  
  List<StockItem> _availableItems = [];
  bool _loadingItems = true;
  String? _globalError;
  bool _submitting = false;
  
  StockItem? _selectedItem;
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _api = StockApi(context.read<ApiClient>());
    _loadItems();
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
    _qtyController.dispose();
    _reasonController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedItem == null) {
      setState(() => _globalError = 'Vui lòng chọn nguyên liệu');
      return;
    }

    final qty = num.tryParse(_qtyController.text.trim());
    if (qty == null || qty <= 0) {
      setState(() => _globalError = 'Số lượng xuất không hợp lệ');
      return;
    }

    if (qty > _selectedItem!.currentQuantity) {
      setState(() => _globalError = 'Số lượng xuất vượt quá tồn kho (${_selectedItem!.currentQuantity} ${_selectedItem!.unit})');
      return;
    }

    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _globalError = 'Vui lòng nhập lý do xuất');
      return;
    }

    setState(() {
      _globalError = null;
      _submitting = true;
    });

    try {
      final note = _noteController.text.trim();
      final finalReason = note.isEmpty ? reason : '$reason - $note';
      
      await _api.export(_selectedItem!.id, qty, finalReason);
      
      if (mounted) {
        setState(() {
          _success = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _globalError = e is ApiException ? e.message : 'Có lỗi xảy ra khi xuất kho');
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
          'Xuất Kho',
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
            const Text('Xuất kho thành công', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cPrimary)),
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

                _buildLabel('Tên nguyên liệu *'),
                const SizedBox(height: 8),
                _loadingItems
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<StockItem>(
                        decoration: _inputDecoration(),
                        isExpanded: true,
                        value: _selectedItem,
                        items: _availableItems.map((item) {
                          return DropdownMenuItem<StockItem>(
                            value: item,
                            child: Text('${item.name} (${item.code})', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedItem = val),
                      ),
                const SizedBox(height: 20),

                _buildLabel('Số lượng xuất *'),
                const SizedBox(height: 8),
                TextField(
                  controller: _qtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  decoration: _inputDecoration(hintText: 'Ví dụ: 2.0'),
                ),
                const SizedBox(height: 20),

                _buildLabel('Lý do xuất *'),
                const SizedBox(height: 8),
                TextField(
                  controller: _reasonController,
                  decoration: _inputDecoration(),
                ),
                const SizedBox(height: 20),

                _buildLabel('Ghi chú'),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  maxLines: 4,
                  decoration: _inputDecoration(hintText: 'Nhập lý do chi tiết (ví dụ: Sữa bị chua, cốc bị bẹp...)'),
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
                    backgroundColor: cBrownDark,
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Segoe UI',
        fontWeight: FontWeight.bold,
        color: cBrownDark,
        fontSize: 15,
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: cTextMuted, fontFamily: 'Segoe UI', fontSize: 14),
      filled: true,
      fillColor: cBgWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: cBorderLight)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: cBorderLight)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: cPrimary)),
    );
  }
}
