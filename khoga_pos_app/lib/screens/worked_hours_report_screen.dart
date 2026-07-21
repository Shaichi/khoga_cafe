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
          };
        }
        summary[r.employeeName]!['workedMinutes'] += r.workedMinutes;
        summary[r.employeeName]!['lateMinutes'] += r.lateMinutes;
        summary[r.employeeName]!['earlyLeaveMinutes'] += r.earlyLeaveMinutes;
        summary[r.employeeName]!['overtimeMinutes'] += r.overtimeMinutes;
        summary[r.employeeName]!['shifts'] += 1;
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
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Date Filter
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
        
        // Report List
        Expanded(
          child: Container(
            color: kBg,
            child: _buildContent(),
          ),
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

    return RefreshIndicator(
      onRefresh: _loadReport,
      color: kBrownDark,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final employee = entries[index].key;
          final stats = entries[index].value;
          
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
                Text(
                  employee,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kBrownDark,
                  ),
                ),
                const Divider(height: 24, color: kBorder),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng giờ làm', style: TextStyle(color: kMuted)),
                    Text(
                      _formatHours(stats['workedMinutes']),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kSuccess,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Số ca đã làm', style: TextStyle(color: kMuted)),
                    Text(
                      '${stats['shifts']}',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: kBrownDark),
                    ),
                  ],
                ),
                if (stats['lateMinutes'] > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Đi trễ', style: TextStyle(color: kMuted)),
                      Text(
                        '${stats['lateMinutes']} phút',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: kDanger),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
