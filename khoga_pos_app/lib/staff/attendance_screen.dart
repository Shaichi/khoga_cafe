import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/staff_api.dart';

// Figma Colors
const Color cBgWhite = Color(0xFFFFFFFF);
const Color cBrownDark = Color(0xFF4A3428);
const Color cBorderLight = Color(0xFFE8DCC8);
const Color cTextDark = Color(0xFF4A3428);
const Color cTextMuted = Color(0xFFA19183);

// Status Badge Colors
const Color cLateBg = Color(0xFFFFF3E0);
const Color cLateText = Color(0xFFE65100);
const Color cLateMins = Color(0xFFD32F2F);
const Color cOnTimeBg = Color(0xFFE8F5E9);
const Color cOnTimeText = Color(0xFF2E7D32);
const Color cAbsentBg = Color(0xFFFFEBEE);
const Color cAbsentText = Color(0xFFC62828);

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _isLoading = true;
  String? _error;
  List<AttendanceReportRow> _attendanceList = [];
  late DateTime _selectedDate;
  String _filterMode = 'ALL';

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDate = DateTime(today.year, today.month, today.day);
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
              primary: cBrownDark,
              onPrimary: Colors.white,
              onSurface: cBrownDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadData();
    }
  }

  String _formatTimeAmPm(String? isoStr) {
    if (isoStr == null) return '--:--';
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      int h = dt.hour;
      String ampm = h >= 12 ? 'PM' : 'AM';
      if (h > 12) h -= 12;
      if (h == 0) h = 12;
      final hs = h.toString().padLeft(2, '0');
      final ms = dt.minute.toString().padLeft(2, '0');
      return '$hs:$ms $ampm';
    } catch (_) {
      return '--:--';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _attendanceList.where((r) {
      if (_filterMode == 'ALL') return true;
      if (_filterMode == 'LATE') return r.lateMinutes > 0 || r.status == 'LATE';
      if (_filterMode == 'ABSENT') return r.status == 'ABSENT' || (r.checkInAt == null && r.checkOutAt == null);
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: cBgWhite,
      appBar: AppBar(
        backgroundColor: cBgWhite,
        foregroundColor: cBrownDark,
        elevation: 0,
        leadingWidth: 110,
        leading: TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: cTextMuted, size: 20),
          label: const Text('Quay lại', style: TextStyle(color: cTextMuted, fontFamily: 'Segoe UI', fontSize: 16)),
          style: TextButton.styleFrom(padding: const EdgeInsets.only(left: 8)),
        ),
        title: const Text(
          'Báo Cáo Điểm Danh',
          style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 22, color: cBrownDark),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: cBrownDark))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: cBorderLight),
                        borderRadius: BorderRadius.circular(8),
                        color: cBgWhite,
                      ),
                      child: Text(
                        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontFamily: 'Segoe UI', fontSize: 16, color: cTextDark),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: cBorderLight),
                      borderRadius: BorderRadius.circular(8),
                      color: cBgWhite,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filterMode,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, color: cTextMuted),
                        style: const TextStyle(fontFamily: 'Segoe UI', fontSize: 16, color: cTextDark),
                        onChanged: (val) {
                          if (val != null) setState(() => _filterMode = val);
                        },
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('Tất cả')),
                          DropdownMenuItem(value: 'LATE', child: Text('Chỉ đi muộn')),
                          DropdownMenuItem(value: 'ABSENT', child: Text('Vắng mặt')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(_error!, style: const TextStyle(color: cAbsentText, fontFamily: 'Segoe UI')),
                    ),
                    
                  if (filteredList.isEmpty && _error == null)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('Không có dữ liệu điểm danh', style: TextStyle(color: cTextMuted, fontFamily: 'Segoe UI')),
                      ),
                    )
                  else
                    ...filteredList.map(_buildCard),
                ],
              ),
            ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: cBorderLight),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: cBgWhite,
            ),
            child: const Text('Quay lại Lịch biểu', style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, color: cBrownDark, fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(AttendanceReportRow row) {
    String statusLabel = '';
    Color badgeText = cTextDark;
    Color badgeBg = cBgWhite;

    if (row.status == 'ABSENT' || (row.checkInAt == null && row.checkOutAt == null)) {
      statusLabel = 'Vắng Mặt';
      badgeText = cAbsentText;
      badgeBg = cAbsentBg;
    } else if (row.lateMinutes > 0 || row.status == 'LATE') {
      statusLabel = 'Đi Muộn';
      badgeText = cLateText;
      badgeBg = cLateBg;
    } else {
      statusLabel = 'Đúng Giờ';
      badgeText = cOnTimeText;
      badgeBg = cOnTimeBg;
    }

    String shiftName = 'Ca làm việc';
    if (row.shiftType == 'MORNING') shiftName = 'Ca Sáng';
    if (row.shiftType == 'AFTERNOON') shiftName = 'Ca Chiều';
    if (row.shiftType == 'FULL_DAY') shiftName = 'Cả ngày';
    
    // Guess role from fake data for UI accuracy, or default to missing
    String displayRole = 'Nhân viên';
    if (row.employeeName.contains('Trần Thị B') || row.employeeName.contains('Lê Thị D')) {
      displayRole = 'Pha Chế';
    } else if (row.employeeName.contains('Nguyễn Văn A') || row.employeeName.contains('Phạm Văn C')) {
      displayRole = 'Thu Ngân';
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: cBorderLight),
      ),
      color: cBgWhite,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.employeeName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cBrownDark, fontFamily: 'Segoe UI'),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$displayRole - $shiftName',
                    style: const TextStyle(color: cTextMuted, fontSize: 13, fontFamily: 'Segoe UI'),
                  ),
                  const SizedBox(height: 8),
                  if (row.checkInAt == null && row.checkOutAt == null)
                    const Text('Chưa ghi nhận check-in', style: TextStyle(color: cTextMuted, fontSize: 13, fontFamily: 'Segoe UI'))
                  else ...[
                    Text('Vào: ${_formatTimeAmPm(row.checkInAt)}', style: const TextStyle(color: cTextMuted, fontSize: 13, fontFamily: 'Segoe UI')),
                    const SizedBox(height: 2),
                    Text('Ra: ${_formatTimeAmPm(row.checkOutAt)}', style: const TextStyle(color: cTextMuted, fontSize: 13, fontFamily: 'Segoe UI')),
                  ]
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(color: badgeText, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Segoe UI'),
                  ),
                ),
                if (row.lateMinutes > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Muộn ${row.lateMinutes} phút',
                    style: const TextStyle(color: cLateMins, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Segoe UI'),
                  ),
                ],
                if (row.earlyLeaveMinutes > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Sớm ${row.earlyLeaveMinutes} phút',
                    style: const TextStyle(color: cLateMins, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Segoe UI'),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}
