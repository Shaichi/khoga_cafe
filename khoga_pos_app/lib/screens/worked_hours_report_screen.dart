import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/staff_api.dart';
import '../theme.dart';

class WorkedHoursReportScreen extends StatefulWidget {
  const WorkedHoursReportScreen({super.key});

  @override
  State<WorkedHoursReportScreen> createState() =>
      _WorkedHoursReportScreenState();
}

class _WorkedHoursReportScreenState extends State<WorkedHoursReportScreen> {
  late AttendanceApi _api;
  bool _loading = true;
  String? _error;
  List<AttendanceReportRow>? _reportRows;

  // Grouped data
  Map<String, Map<String, dynamic>> _employeeSummary = {};

  // Defaults to first day of month to today
  DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final client = context.read<ApiClient>();
    _api = AttendanceApi(client);
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

      // Group by employee name
      final Map<String, Map<String, dynamic>> summary = {};
      for (var r in rows) {
        summary.putIfAbsent(
          r.employeeName,
          () => {
            'workedMinutes': 0,
            'lateMinutes': 0,
            'earlyLeaveMinutes': 0,
            'overtimeMinutes': 0,
            'shifts': 0,
          },
        );
        summary[r.employeeName]!['workedMinutes'] += r.workedMinutes;
        summary[r.employeeName]!['lateMinutes'] += r.lateMinutes;
        summary[r.employeeName]!['earlyLeaveMinutes'] += r.earlyLeaveMinutes;
        summary[r.employeeName]!['overtimeMinutes'] += r.overtimeMinutes;
        summary[r.employeeName]!['shifts'] += 1;
      }

      if (mounted) {
        setState(() {
          _reportRows = rows;
          _employeeSummary = summary;
          _loading = false;
        });
      }
    } catch (e, stack) {
      if (mounted) {
        setState(() {
          _error =
              'Lỗi: $e\n\n${stack.toString().substring(0, stack.toString().length.clamp(0, 300))}';
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

  void _exportCsv() async {
    final client = context.read<ApiClient>();
    final fromStr = _fromDate.toIso8601String().substring(0, 10);
    final toStr = _toDate.toIso8601String().substring(0, 10);

    final url = Uri.parse(
      'http://localhost:8080/api/v1/attendance/export?from=$fromStr&to=$toStr&format=csv&token=${client.token}',
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể mở link tải. Vui lòng thử lại.'),
          ),
        );
      }
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: kBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_fromDate.day}/${_fromDate.month}/${_fromDate.year}  -  ${_toDate.day}/${_toDate.month}/${_toDate.year}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _loadReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrownDark,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Icon(Icons.refresh, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _exportCsv,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Xuất CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kSuccess,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Content
        Expanded(child: _buildContent()),
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
              child: const Text(
                'Thử lại',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
    if (_employeeSummary.isEmpty) {
      return const Center(
        child: Text(
          'Không có dữ liệu trong khoảng thời gian này.',
          style: TextStyle(color: kMuted),
        ),
      );
    }

    final entries = _employeeSummary.entries.toList();

    return RefreshIndicator(
      onRefresh: _loadReport,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder),
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(kBg),
            columns: const [
              DataColumn(
                label: Text(
                  'Nhân viên',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kBrownDark,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Giờ làm',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kBrownDark,
                  ),
                ),
              ),
            ],
            rows: entries.map((entry) {
              final employee = entry.key;
              final stats = entry.value;
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      employee,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  DataCell(
                    Text(
                      _formatHours(stats['workedMinutes']),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kSuccess,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
