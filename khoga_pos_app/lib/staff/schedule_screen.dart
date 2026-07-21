import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/staff_api.dart';
import '../theme.dart';
import 'schedule_form_screen.dart';

/// Screen 30 — staff schedule. Store Manager view.
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

  late DateTime _today;
  late DateTime _selectedDate;
  late DateTime _startDate;
  late DateTime _endDate;
  late List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    _api = ScheduleApi(context.read<ApiClient>());
    
    _today = DateTime.now();
    _selectedDate = DateTime(_today.year, _today.month, _today.day);
    
    // Generate 38 days (-7 to +30)
    _startDate = _selectedDate.subtract(const Duration(days: 7));
    _endDate = _selectedDate.add(const Duration(days: 30));
    
    _dates = [];
    for (int i = 0; i <= 37; i++) {
      _dates.add(_startDate.add(Duration(days: i)));
    }

    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fromStr = '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}';
      final toStr = '${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}';
      
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
      final today = DateTime(_today.year, _today.month, _today.day);
      if (_selectedDate.isBefore(today)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể thêm ca làm việc trong quá khứ', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
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
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: kBrownDark,
        elevation: 1,
        title: const Text('Lịch làm việc', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildCalendarStrip(),
            const Divider(height: 1, color: kBorder),
            Expanded(child: _buildShiftList()),
          ],
        ),
      ),
      floatingActionButton: _selectedDate.isBefore(DateTime(_today.year, _today.month, _today.day))
          ? null
          : FloatingActionButton(
              key: const Key('schedule-add'),
              backgroundColor: kBrown,
              foregroundColor: Colors.white,
              onPressed: () => _openForm(),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildCalendarStrip() {
    return Container(
      color: Colors.white,
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        itemCount: _dates.length,
        itemBuilder: (context, index) {
          final date = _dates[index];
          final isSelected = date.isAtSameMomentAs(_selectedDate);
          final isToday = date.isAtSameMomentAs(DateTime(_today.year, _today.month, _today.day));

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = date);
            },
            child: Container(
              width: 56,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? kBrown : (isToday ? kBg : Colors.transparent),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? kBrown : (isToday ? kBorder : Colors.transparent)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getWeekday(date.weekday),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white70 : kMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : kBrownDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShiftList() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: kBrown));
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: kDanger)));

    final selectedDateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final dayShifts = _shifts.where((s) => s.shiftDate == selectedDateStr).toList();

    if (dayShifts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: kBorder),
            SizedBox(height: 16),
            Text('Không có ca làm việc nào', style: TextStyle(color: kMuted, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.separated(
      key: const Key('schedule-view'),
      padding: const EdgeInsets.all(16),
      itemCount: dayShifts.length,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _shiftCard(dayShifts[i]),
    );
  }

  Widget _shiftCard(ScheduleShift s) {
    Color typeColor;
    switch (s.shiftType) {
      case 'MORNING':
        typeColor = Colors.lightBlue;
        break;
      case 'AFTERNOON':
        typeColor = Colors.orange;
        break;
      case 'FULL_DAY':
        typeColor = kSuccess;
        break;
      default:
        typeColor = kMuted;
    }

    // Initials
    final names = s.employeeName.split(' ').where((n) => n.isNotEmpty).toList();
    String initials = '';
    if (names.isNotEmpty) {
      initials = names.first[0].toUpperCase();
      if (names.length > 1) initials += names.last[0].toUpperCase();
    }

    return InkWell(
      key: Key('shift-${s.id}'),
      onTap: () => _openForm(s),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: typeColor.withValues(alpha: 0.1),
              child: Text(
                initials,
                style: TextStyle(color: typeColor, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.employeeName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kBrownDark),
                        ),
                      ),
                      if (s.crossBranch)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: kGold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                          child: const Text('Liên chi nhánh', style: TextStyle(color: kBrown, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: typeColor),
                      const SizedBox(width: 4),
                      Text(
                        _shiftTypeLabel(s.shiftType),
                        style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  if (s.posRegisterId != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.point_of_sale, size: 14, color: kMuted),
                        const SizedBox(width: 4),
                        Text('Máy POS: ${s.posRegisterId}', style: const TextStyle(color: kMuted, fontSize: 13)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: kMuted),
          ],
        ),
      ),
    );
  }

  String _getWeekday(int weekday) {
    switch (weekday) {
      case 1: return 'T2';
      case 2: return 'T3';
      case 3: return 'T4';
      case 4: return 'T5';
      case 5: return 'T6';
      case 6: return 'T7';
      case 7: return 'CN';
      default: return '';
    }
  }

  String _shiftTypeLabel(String t) => switch (t) {
        'MORNING' => 'Ca sáng',
        'AFTERNOON' => 'Ca chiều',
        'FULL_DAY' => 'Cả ngày',
        _ => t,
      };
}
