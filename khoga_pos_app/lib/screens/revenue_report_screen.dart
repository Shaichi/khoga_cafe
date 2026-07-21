import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/report_api.dart';
import '../format.dart';
import '../theme.dart';

class RevenueReportScreen extends StatefulWidget {
  const RevenueReportScreen({super.key});

  @override
  State<RevenueReportScreen> createState() => _RevenueReportScreenState();
}

class _RevenueReportScreenState extends State<RevenueReportScreen> {
  late ReportApi _api;
  bool _loading = true;
  String? _error;
  StoreRevenueReport? _report;

  // Defaults to today
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final client = context.read<ApiClient>();
    _api = ReportApi(client);
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final fromStr = _fromDate.toIso8601String().substring(0, 10);
      final toStr = _toDate.toIso8601String().substring(0, 10);
      final r = await _api.getStoreRevenue(fromStr, toStr);
      if (mounted) {
        setState(() {
          _report = r;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Lỗi kết nối máy chủ';
          _loading = false;
        });
      }
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kBrownDark,
              onPrimary: Colors.white,
              onSurface: kBrownDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _loadReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Row(
                children: [
                  Icon(Icons.arrow_back, color: kMuted, size: 20),
                  SizedBox(width: 4),
                  Text('Quay lại', style: TextStyle(color: kMuted, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Text('Báo Cáo Doanh Thu', style: TextStyle(color: kBrownDark, fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GestureDetector(
                onTap: _selectDateRange,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: kBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _fromDate.year == _toDate.year && _fromDate.month == _toDate.month && _fromDate.day == _toDate.day
                        ? _fromDate.toIso8601String().substring(0, 10)
                        : '${_fromDate.toIso8601String().substring(0, 10)}  -  ${_toDate.toIso8601String().substring(0, 10)}',
                    style: const TextStyle(color: kBrownDark, fontSize: 15),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _buildContent(),
            ),
            // Bottom Actions
            Container(
              padding: const EdgeInsets.all(16),
              color: kBg,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showExportDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3E2723), // Dark brown
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('XUẤT BÁO CÁO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kBrownDark,
                        side: const BorderSide(color: kBorder),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.white,
                      ),
                      child: const Text('Quay lại Trang chủ', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kBrownDark));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: kDanger)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadReport,
              style: ElevatedButton.styleFrom(backgroundColor: kBrownDark),
              child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    if (_report == null) return const SizedBox.shrink();

    final r = _report!;
    return RefreshIndicator(
      onRefresh: _loadReport,
      color: kBrownDark,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(r),
          const SizedBox(height: 16),
          _buildPaymentBreakdownCard(r.payments),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(StoreRevenueReport r) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Tóm tắt doanh số chi nhánh', style: TextStyle(fontWeight: FontWeight.bold, color: kMuted, fontSize: 13)),
          ),
          const Divider(height: 1, color: kBorder),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('Doanh thu thuần', '${formatVnd(r.netRevenue)} VND', valueColor: kSuccess),
                const SizedBox(height: 12),
                _buildInfoRow('Đơn hàng hoàn thành', '${r.completedOrders} đơn'),
                const SizedBox(height: 12),
                _buildInfoRow('Tổng sai lệch két', '${formatVnd(r.discrepancyTotal)} VND'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdownCard(PaymentBreakdown pb) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Hình thức thanh toán', style: TextStyle(fontWeight: FontWeight.bold, color: kMuted, fontSize: 13)),
          ),
          const Divider(height: 1, color: kBorder),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPaymentRow('Tiền mặt (Cash)', '${formatVnd(pb.cash)} VND', const Color(0xFF4CAF50)),
                const SizedBox(height: 12),
                _buildPaymentRow('Thẻ ngân hàng (Card)', '${formatVnd(pb.card)} VND', const Color(0xFF2196F3)),
                const SizedBox(height: 12),
                _buildPaymentRow('Chuyển khoản VietQR', '${formatVnd(pb.vietqr)} VND', const Color(0xFFFF9800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: kBrownDark)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor ?? kBrownDark, fontSize: valueColor != null ? 16 : 14)),
      ],
    );
  }

  Widget _buildPaymentRow(String label, String value, Color dotColor) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: kBrownDark)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: kBrownDark)),
      ],
    );
  }

  void _showExportDialog() {
    String selectedFormat = 'pdf';
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Xuất Báo Cáo', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kBrownDark)),
                    const SizedBox(height: 24),
                    const Text('Định dạng file xuất', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kBrown)),
                    const SizedBox(height: 12),
                    _buildRadioOption('pdf', 'Tài liệu PDF (.pdf)', selectedFormat, (v) => setState(() => selectedFormat = v!)),
                    _buildRadioOption('xlsx', 'Bảng tính Excel (.xlsx)', selectedFormat, (v) => setState(() => selectedFormat = v!)),
                    _buildRadioOption('csv', 'File dữ liệu CSV (.csv)', selectedFormat, (v) => setState(() => selectedFormat = v!)),
                    const SizedBox(height: 20),
                    const Text('Phạm vi dữ liệu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kBrown)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEBEBEB)),
                      ),
                      child: Text(
                        _fromDate.year == _toDate.year && _fromDate.month == _toDate.month && _fromDate.day == _toDate.day
                            ? _fromDate.toIso8601String().substring(0, 10)
                            : '${_fromDate.toIso8601String().substring(0, 10)}  -  ${_toDate.toIso8601String().substring(0, 10)}',
                        style: const TextStyle(color: kMuted, fontSize: 15),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kBrownDark,
                              side: const BorderSide(color: Color(0xFFEBEBEB)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('HỦY', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang tải xuống...')));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kBrownDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('TẢI XUỐNG', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildRadioOption(String value, String label, String groupValue, ValueChanged<String?> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(
              groupValue == value ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: kBrownDark,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Colors.black87, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
