import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/stock_api.dart';
import '../format.dart';
import '../theme.dart';

class ExportStockItemModel {
  final StockItem stockItem;
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  String? error;
  String? reasonError;

  ExportStockItemModel(this.stockItem);

  void dispose() {
    qtyController.dispose();
    reasonController.dispose();
  }
}

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
  
  final List<ExportStockItemModel> _exportList = [];
  StockItem? _selectedDropdownItem;
  
  bool _success = false;
  int _successCount = 0;

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
    for (var item in _exportList) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem(StockItem item) {
    if (_exportList.any((i) => i.stockItem.id == item.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nguyên liệu này đã có trong danh sách xuất')),
      );
      return;
    }
    setState(() {
      _exportList.add(ExportStockItemModel(item));
      _selectedDropdownItem = null;
    });
  }

  void _removeItem(int index) {
    setState(() {
      final item = _exportList.removeAt(index);
      item.dispose();
    });
  }

  Future<void> _submit() async {
    if (_exportList.isEmpty) {
      setState(() => _globalError = 'Vui lòng chọn ít nhất 1 nguyên liệu để xuất');
      return;
    }

    bool hasValidationErrors = false;
    for (var item in _exportList) {
      final qty = num.tryParse(item.qtyController.text.trim());
      if (qty == null || qty <= 0) {
        item.error = 'Không hợp lệ';
        hasValidationErrors = true;
      } else if (qty > item.stockItem.currentQuantity) {
        item.error = 'Vượt quá tồn';
        hasValidationErrors = true;
      } else {
        item.error = null;
      }

      if (item.reasonController.text.trim().isEmpty) {
        item.reasonError = 'Bắt buộc';
        hasValidationErrors = true;
      } else {
        item.reasonError = null;
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
      final futures = _exportList.map((item) async {
        final qty = num.parse(item.qtyController.text.trim());
        return _api.export(item.stockItem.id, qty, item.reasonController.text.trim());
      });
      
      await Future.wait(futures);
      
      if (mounted) {
        setState(() {
          _successCount = _exportList.length;
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
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: kBrownDark,
        elevation: 1,
        title: const Text(
          'Xuất kho (Bulk Export)',
          style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 18),
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
            const Text('Xuất kho thành công', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kBrown)),
            const SizedBox(height: 8),
            Text('Đã xuất thành công $_successCount mặt hàng', style: const TextStyle(color: kMuted)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrown,
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
        if (_globalError != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kDanger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kDanger),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: kDanger),
                const SizedBox(width: 12),
                Expanded(child: Text(_globalError!, style: const TextStyle(color: kDanger, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          
        Padding(
          padding: const EdgeInsets.all(16),
          child: _loadingItems
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<StockItem>(
                  decoration: InputDecoration(
                    labelText: 'Chọn nguyên liệu để xuất...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
                  ),
                  value: _selectedDropdownItem,
                  items: _availableItems.map((item) {
                    return DropdownMenuItem<StockItem>(
                      value: item,
                      child: Text('${item.name} (${item.code})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) _addItem(val);
                  },
                ),
        ),
        
        Expanded(
          child: _exportList.isEmpty
              ? const Center(
                  child: Text(
                    'Chưa có mặt hàng nào.\nVui lòng chọn từ danh sách trên.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kMuted, fontFamily: 'Segoe UI'),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _exportList.length,
                  itemBuilder: (context, index) {
                    final itemModel = _exportList[index];
                    final stock = itemModel.stockItem;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  stock.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: kBrownDark, fontSize: 16),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: kDanger),
                                onPressed: () => _removeItem(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Tồn hiện tại: ${formatVnd(stock.currentQuantity)} ${stock.unit}', style: const TextStyle(color: kMuted, fontSize: 13)),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: itemModel.qtyController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                  decoration: InputDecoration(
                                    labelText: 'SL (${stock.unit}) *',
                                    errorText: itemModel.error,
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: itemModel.reasonController,
                                  decoration: InputDecoration(
                                    labelText: 'Lý do (Hỏng...) *',
                                    errorText: itemModel.reasonError,
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: kBorder)),
          ),
          child: ElevatedButton(
            onPressed: _submitting || _exportList.isEmpty ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrown,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _submitting
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('XÁC NHẬN XUẤT KHO (${_exportList.length} MÓN)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}
