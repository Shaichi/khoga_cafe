import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/staff_api.dart';
import '../theme.dart';

class WorkedHoursReportScreen extends StatefulWidget {
  const WorkedHoursReportScreen({super.key});

  @override
  State<WorkedHoursReportScreen> createState() => _WorkedHoursReportScreenState();
}

class _WorkedHoursReportScreenState extends State<WorkedHoursReportScreen> {
  late AttendanceApi _api;
  bool _loading = true;
  String? _error;

  Map<String, Map<String, dynamic>> _employeeSummary = {};

  DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _api = AttendanceApi(context.read<ApiClient>());
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
      final rows = await _api.report(from: fromStr, to: toStr);

      Map<String, Map<String, dynamic>> summary = {};
      for (var r in rows) {
        if (!summary.containsKey(r.employeeName)) {
          summary[r.employeeName] = {
            'workedMinutes': 0,
            'lateMinutes': 0,
            'earlyLeaveMinutes': 0,
            'overtimeMinutes': 0,
            'shifts': 0,
            'warnings': 0,
          };
        }
        summary[r.employeeName]!['workedMinutes'] += r.workedMinutes;
        summary[r.employeeName]!['lateMinutes'] += r.lateMinutes;
        summary[r.employeeName]!['earlyLeaveMinutes'] += r.earlyLeaveMinutes;
        summary[r.employeeName]!['overtimeMinutes'] += r.overtimeMinutes;
        summary[r.employeeName]!['shifts'] += 1;
        if (r.lateMinutes > 0 || r.earlyLeaveMinutes > 0) {
          summary[r.employeeName]!['warnings'] = (summary[r.employeeName]!['warnings'] as int) + 1;
        }
      }

      if (mounted) {
        setState(() {
          _employeeSummary = summary;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không thể tải báo cáo: $e';
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

  String _formatHours(int totalMinutes) {
    final double hours = totalMinutes / 60.0;
    return hours.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kBrownDark),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: false,
        titleSpacing: 0,
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('Báo Cáo Giờ Công', style: TextStyle(color: kBrownDark, fontWeight: FontWeight.bold, fontSize: 20)),
        ),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEAE2D8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('Chi nhánh Nguyễn Du', style: TextStyle(color: kBrownDark, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Date Filter Box
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kBg,
                  border: Border.all(color: kBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kỳ tính công', style: TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _selectDateRange,
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: kBorder),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _fromDate.toIso8601String().substring(0, 10),
                                style: const TextStyle(color: kBrownDark, fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('-', style: TextStyle(color: kMuted)),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: _selectDateRange,
                            child: Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: kBorder),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _toDate.toIso8601String().substring(0, 10),
                                style: const TextStyle(color: kBrownDark, fontSize: 14),
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
            
            // Table List
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildContent(),
              ),
            ),
            
            // Bottom Buttons
            Container(
              padding: const EdgeInsets.all(16),
              color: kBg,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {}, // TODO: Export CSV
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3E2723), // Dark brown
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('XUẤT FILE CSV', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {}, // TODO: Export PDF
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3E2723), // Dark brown
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('XUẤT FILE PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
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
                      child: const Text('QUAY LẠI', style: TextStyle(fontWeight: FontWeight.bold)),
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
            Text(_error!, style: const TextStyle(color: kDanger), textAlign: TextAlign.center),
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
    if (_employeeSummary.isEmpty) {
      return const Center(
        child: Text('Không có dữ liệu giờ làm trong khoảng này.', style: TextStyle(color: kMuted)),
      );
    }

    final entries = _employeeSummary.entries.toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF6EBE5),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(11), topRight: Radius.circular(11)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Nhân viên', style: TextStyle(fontWeight: FontWeight.bold, color: kBrownDark))),
                Expanded(flex: 2, child: Text('Số\nngày', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: kBrownDark))),
                Expanded(flex: 2, child: Text('Giờ\ncông', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: kBrownDark))),
                Expanded(flex: 2, child: Text('Cảnh\nbáo', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: kBrownDark))),
              ],
            ),
          ),
          // Table Rows
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: kBorder),
              itemBuilder: (context, index) {
                final employee = entries[index].key;
                final stats = entries[index].value;
                final warnings = stats['warnings'] as int;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(employee, style: const TextStyle(fontWeight: FontWeight.bold, color: kBrownDark)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('${stats['shifts']}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, color: kBrownDark)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _formatHours(stats['workedMinutes']),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: kSuccess),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: warnings > 0
                            ? Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text('($warnings)', style: const TextStyle(color: kWarning, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              )
                            : const Text('-', textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
