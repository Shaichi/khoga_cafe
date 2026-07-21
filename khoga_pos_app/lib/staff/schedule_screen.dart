import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/staff_api.dart';
import 'attendance_screen.dart';
import 'schedule_form_screen.dart';

// Figma Colors
const Color cBgWhite = Color(0xFFFFFFFF);
const Color cBorderLight = Color(0xFFEADDD3);
const Color cTextDark = Color(0xFF2C1A11);
const Color cTextMuted = Color(0xFF8C766C);
const Color cBrownDark = Color(0xFF3D2314);
const Color cPrimary = Color(0xFF5C3826);
const Color cDanger = Color(0xFFC62828);

/// Screen 30 — staff schedule. Store Manager view based on Figma design.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late final ScheduleApi _api;
  List<ScheduleShift> _shifts = const [];
  bool _loading = true;
  String? _error;

  late DateTime _selectedDate;
  String _roleFilter = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _api = ScheduleApi(context.read<ApiClient>());
    final today = DateTime.now();
    _selectedDate = DateTime(today.year, today.month, today.day);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final start = _selectedDate.subtract(const Duration(days: 7));
      final end = _selectedDate.add(const Duration(days: 30));
      final fromStr = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
      final toStr = '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
      
      final shifts = await _api.list(from: fromStr, to: toStr);
      if (mounted) {
        setState(() {
          _shifts = shifts;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Không tải được lịch làm việc');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([ScheduleShift? existing]) async {
    // Không cho phép mở form để thêm ca mới vào ngày quá khứ
    if (existing == null) {
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      if (_selectedDate.isBefore(todayOnly)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể thêm ca làm việc trong quá khứ', style: TextStyle(color: Colors.white)), backgroundColor: cDanger),
          );
        }
        return;
      }
    }
    
    // Pass selected date to form
    final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => ScheduleFormScreen(existing: existing, defaultDate: dateStr)),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBgWhite,
      appBar: AppBar(
        backgroundColor: cBgWhite,
        foregroundColor: cBrownDark,
        elevation: 0,
        leadingWidth: 110,
        leading: InkWell(
          onTap: () => Navigator.of(context).pop(),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_back, color: cTextMuted, size: 20),
              SizedBox(width: 4),
              Text('Quay lại', style: TextStyle(color: cTextMuted, fontSize: 16, fontFamily: 'Segoe UI')),
            ],
          ),
        ),
        title: const Text(
          'Lịch Làm Việc',
          style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 22, color: cBrownDark),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildDateSelector(),
            _buildRoleFilter(),
            const SizedBox(height: 16),
            Expanded(child: _buildShiftList()),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: cBgWhite,
          border: Border(top: BorderSide(color: Colors.transparent)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => _openForm(),
              style: ElevatedButton.styleFrom(
                backgroundColor: cBrownDark,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('+ Phân Ca Mới', style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AttendanceScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                side: const BorderSide(color: cBorderLight),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Xem Báo Cáo Điểm Danh', style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, color: cBrownDark, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: cTextMuted, size: 20),
            onPressed: () {
              setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
              _load();
            },
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: cBorderLight),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                dateStr,
                style: const TextStyle(fontSize: 16, color: cBrownDark, fontFamily: 'Segoe UI'),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: cTextMuted, size: 20),
            onPressed: () {
              setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
              _load();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilter() {
    const roles = ['Tất cả', 'Thu ngân', 'Pha chế'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: roles.map((role) {
          final isSelected = _roleFilter == role;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _roleFilter = role),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? cBrownDark : cBgWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? cBrownDark : cBorderLight),
                ),
                alignment: Alignment.center,
                child: Text(
                  role,
                  style: TextStyle(
                    color: isSelected ? Colors.white : cBrownDark,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Segoe UI',
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildShiftList() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: cBrownDark));
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: cDanger)));

    final selectedDateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final dayShifts = _shifts.where((s) {
      if (s.shiftDate != selectedDateStr) return false;
      if (_roleFilter != 'Tất cả') {
        if (_roleFilter == 'Thu ngân' && !s.role.toLowerCase().contains('thu ngân') && !s.role.toLowerCase().contains('cashier')) return false;
        if (_roleFilter == 'Pha chế' && !s.role.toLowerCase().contains('pha chế') && !s.role.toLowerCase().contains('barista')) return false;
      }
      return true;
    }).toList();

    if (dayShifts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: cBorderLight),
            SizedBox(height: 16),
            Text('Không có ca làm việc nào', style: TextStyle(color: cTextMuted, fontSize: 16, fontFamily: 'Segoe UI')),
          ],
        ),
      );
    }

    return ListView.separated(
      key: const Key('schedule-view'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: dayShifts.length,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _shiftCard(dayShifts[i]),
    );
  }

  Widget _shiftCard(ScheduleShift s) {
    // Role badge
    String badgeText = s.role;
    if (badgeText.isEmpty) badgeText = 'Nhân viên';
    
    Color badgeBg;
    Color badgeColor;
    
    if (badgeText.toLowerCase().contains('thu ngân') || badgeText.toLowerCase().contains('cashier')) {
      badgeText = 'Thu Ngân';
      badgeBg = const Color(0xFFE3F2FD);
      badgeColor = const Color(0xFF1565C0);
    } else if (badgeText.toLowerCase().contains('pha chế') || badgeText.toLowerCase().contains('barista')) {
      badgeText = 'Pha Chế';
      badgeBg = const Color(0xFFEFEBE9);
      badgeColor = const Color(0xFF4E342E);
    } else {
      badgeBg = const Color(0xFFF5F5F5);
      badgeColor = const Color(0xFF616161);
    }

    // Time text
    String timeStr = '';
    if (s.shiftStartTime != null && s.shiftEndTime != null) {
      timeStr = '${s.shiftStartTime} - ${s.shiftEndTime}';
    } else if (s.shiftType == 'MORNING') {
      timeStr = '06:00 - 14:00';
    } else if (s.shiftType == 'AFTERNOON') {
      timeStr = '14:00 - 22:00';
    } else {
      timeStr = '08:00 - 17:00';
    }
    
    String label = switch(s.shiftType) {
      'MORNING' => 'Ca sáng',
      'AFTERNOON' => 'Ca chiều',
      'FULL_DAY' => 'Cả ngày',
      _ => 'Ca làm việc'
    };

    String posStr = s.posRegisterId?.isNotEmpty == true ? s.posRegisterId! : 'Không';

    return InkWell(
      key: Key('shift-${s.id}'),
      onTap: () => _openForm(s),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: cBgWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cBorderLight),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        s.employeeName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cBrownDark, fontFamily: 'Segoe UI'),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Segoe UI'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$label ($timeStr)',
                    style: const TextStyle(color: cTextMuted, fontSize: 13, fontFamily: 'Segoe UI'),
                  ),
                  if (!(s.role.toLowerCase().contains('pha chế') || s.role.toLowerCase().contains('barista'))) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Máy POS phân bổ: $posStr',
                      style: const TextStyle(color: cTextMuted, fontSize: 13, fontFamily: 'Segoe UI'),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: cTextMuted),
          ],
        ),
      ),
    );
  }
}
