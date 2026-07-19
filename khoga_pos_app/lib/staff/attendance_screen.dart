import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../auth/auth_controller.dart';
import '../format.dart';
import '../api/staff_api.dart';
import '../theme.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _isLoading = true;
  String? _error;
  List<AttendanceReportRow> _attendanceList = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = context.read<ApiClient>();
      final dt = _selectedDate;
      final dateStr = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      final report = await AttendanceApi(client).report(from: dateStr, to: dateStr);
      
      setState(() {
        _attendanceList = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kBrown,
              onPrimary: Colors.white,
              onSurface: kBrownDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
    }
  }

  Future<void> _pickTimeAndUpdate(AttendanceReportRow row, bool isCheckIn) async {
    String? currentVal = isCheckIn ? row.checkInAt : row.checkOutAt;
    TimeOfDay initialTime = TimeOfDay.now();
    
    if (currentVal != null) {
      try {
        final dt = DateTime.parse(currentVal).toLocal();
        initialTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      } catch (_) {}
    } else {
      String? defaultVal = isCheckIn ? row.scheduledStart : row.scheduledEnd;
      if (defaultVal != null) {
        try {
          final dt = DateTime.parse(defaultVal).toLocal();
          initialTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
        } catch (_) {}
      }
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kBrown,
              onPrimary: Colors.white,
              onSurface: kBrownDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return; // User canceled

    // Create a DateTime object combining _selectedDate and pickedTime
    final combinedDt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    final isoStr = combinedDt.toIso8601String();

    String? newCheckIn = row.checkInAt;
    String? newCheckOut = row.checkOutAt;

    if (isCheckIn) {
      newCheckIn = isoStr;
    } else {
      if (newCheckIn == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập Giờ Vào trước khi nhập Giờ Ra')),
        );
        return;
      }
      newCheckOut = isoStr;
    }

    _submitManualUpdate(row.userId, newCheckIn, newCheckOut);
  }

  Future<void> _clearTime(AttendanceReportRow row, bool isCheckIn) async {
    String? newCheckIn = row.checkInAt;
    String? newCheckOut = row.checkOutAt;

    if (isCheckIn) {
      newCheckIn = null;
      newCheckOut = null; // Clearing CheckIn also clears CheckOut
    } else {
      newCheckOut = null;
    }
    _submitManualUpdate(row.userId, newCheckIn, newCheckOut);
  }

  Future<void> _submitManualUpdate(String userId, String? checkIn, String? checkOut) async {
    try {
      final client = context.read<ApiClient>();
      await AttendanceApi(client).manualUpdate(
        userId: userId,
        checkInAt: checkIn,
        checkOutAt: checkOut,
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  void _exportCsv() async {
    final client = context.read<ApiClient>();
    final fromStr = DateTime(_selectedDate.year, _selectedDate.month, 1).toIso8601String().substring(0, 10);
    // last day of month
    final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final toStr = lastDay.toIso8601String().substring(0, 10);
    
    // Create Uri with JWT token so the backend can authenticate the browser request
    final url = Uri.parse('http://localhost:8080/api/v1/attendance/export?from=$fromStr&to=$toStr&format=csv&token=${client.token}');
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở link tải. Vui lòng thử lại.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Điểm Danh'),
        backgroundColor: Colors.white,
        foregroundColor: kBrownDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Xuất báo cáo (Tháng này)',
            onPressed: _exportCsv,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selectDate,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    final displayDate = '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Ngày: $displayDate',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kBrownDark),
          ),
          TextButton(
            onPressed: _selectDate,
            style: TextButton.styleFrom(foregroundColor: kBrown),
            child: const Text('Chọn ngày'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Lỗi: $_error', style: const TextStyle(color: kDanger)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_attendanceList.isEmpty) {
      return const Center(child: Text('Không có ca làm việc nào được phân công', style: TextStyle(color: kMuted)));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _attendanceList.length,
        itemBuilder: (context, index) {
          final row = _attendanceList[index];
          final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
          final isPast = _selectedDate.isBefore(today);
          return _buildAttendanceCard(row, isPast);
        },
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceReportRow row, bool isPast) {
    final formatTime = (String? dtStr) {
      if (dtStr == null) return '--:--';
      try {
        final dt = DateTime.parse(dtStr).toLocal();
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        return '$h:$m';
      } catch (_) {
        return '--:--';
      }
    };

    String shiftName = 'Không xác định';
    if (row.shiftType == 'MORNING') shiftName = 'Sáng';
    if (row.shiftType == 'AFTERNOON') shiftName = 'Chiều';
    if (row.shiftType == 'FULL_DAY') shiftName = 'Cả ngày';
    if (row.shiftType == null && row.scheduledStart == null) shiftName = 'Ca tăng cường'; // Unscheduled

    final isPresent = row.checkInAt != null;
    final isCheckedOut = row.checkOutAt != null;

    Color statusColor = kMuted;
    if (row.status == 'PRESENT') statusColor = kSuccess;
    if (row.status == 'LATE') statusColor = kWarning;
    if (row.status == 'ABSENT') statusColor = kDanger;
    if (row.status == 'EARLY_LEAVE') statusColor = kWarning;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  row.employeeName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kBrownDark),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    row.status,
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ca $shiftName: ${formatTime(row.scheduledStart)} - ${formatTime(row.scheduledEnd)}',
              style: const TextStyle(color: kMuted),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildActionBtn(
                    label: 'Giờ Vào',
                    timeStr: row.checkInAt,
                    isActive: isPresent,
                    isPast: isPast,
                    onPickTime: isPast ? null : () => _pickTimeAndUpdate(row, true),
                    onClearTime: isPast ? null : () => _clearTime(row, true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionBtn(
                    label: 'Giờ Ra',
                    timeStr: row.checkOutAt,
                    isActive: isCheckedOut,
                    isPast: isPast,
                    onPickTime: isPast ? null : () => _pickTimeAndUpdate(row, false),
                    onClearTime: isPast ? null : () => _clearTime(row, false),
                  ),
                ),
              ],
            ),
            if (row.lateMinutes > 0 || row.earlyLeaveMinutes > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    if (row.lateMinutes > 0)
                      Text('Trễ: ${row.lateMinutes} phút ', style: const TextStyle(color: kWarning, fontSize: 12)),
                    if (row.earlyLeaveMinutes > 0)
                      Text('Về sớm: ${row.earlyLeaveMinutes} phút', style: const TextStyle(color: kWarning, fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required String label,
    required String? timeStr,
    required bool isActive,
    required bool isPast,
    VoidCallback? onPickTime,
    VoidCallback? onClearTime,
  }) {
    final formatTime = (String? dtStr) {
      if (dtStr == null) return '--:--';
      try {
        final dt = DateTime.parse(dtStr).toLocal();
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        return '$h:$m';
      } catch (_) {
        return '--:--';
      }
    };

    return InkWell(
      onTap: onPickTime,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? kSuccess.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? kSuccess : kBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(label, style: TextStyle(color: isActive ? kSuccess : kMuted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    timeStr == null ? 'Nhập giờ' : formatTime(timeStr),
                    style: TextStyle(
                      color: isActive ? kSuccess : kBrownDark,
                      fontWeight: FontWeight.bold,
                      fontSize: timeStr == null ? 12 : 16,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive && !isPast)
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: kDanger),
                onPressed: onClearTime,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}
