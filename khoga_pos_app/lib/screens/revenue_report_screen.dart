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
    return Column(
      children: [
        // Filter bar
        Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.date_range, color: kBrownDark),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: _selectDateRange,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: kBorder),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_fromDate.day}/${_fromDate.month}/${_fromDate.year}  -  ${_toDate.day}/${_toDate.month}/${_toDate.year}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: kBrownDark),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),

          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
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
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(
            title: 'Doanh thu thuần',
            value: '${formatVnd(r.netRevenue)}đ',
            icon: Icons.account_balance_wallet,
            color: kSuccess,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Đơn thành công',
                  value: '${r.completedOrders}',
                  icon: Icons.receipt_long,
                  color: kBrownDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Chênh lệch két',
                  value: '${formatVnd(r.discrepancyTotal)}đ',
                  icon: Icons.money_off,
                  color: r.discrepancyTotal < 0 ? kDanger : (r.discrepancyTotal > 0 ? kSuccess : kMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Phương thức thanh toán',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBrownDark),
          ),
          const SizedBox(height: 12),
          _buildPaymentBreakdown(r.payments),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: kMuted, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdown(PaymentBreakdown pb) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          _buildPaymentRow('Tiền mặt', '${formatVnd(pb.cash)}đ', Icons.money),
          const Divider(height: 1, color: kBorder),
          _buildPaymentRow('Thẻ ngân hàng', '${formatVnd(pb.card)}đ', Icons.credit_card),
          const Divider(height: 1, color: kBorder),
          _buildPaymentRow('VietQR', '${formatVnd(pb.vietqr)}đ', Icons.qr_code),
          const Divider(height: 1, color: kBorder),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kBrown.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng thu', style: TextStyle(fontWeight: FontWeight.bold, color: kBrownDark)),
                Text(
                  '${formatVnd(pb.total)}đ',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kBrownDark),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String amount, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: kMuted),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: kBrownDark)),
          const Spacer(),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
