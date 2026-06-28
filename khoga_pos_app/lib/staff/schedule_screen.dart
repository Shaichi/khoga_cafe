import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/staff_api.dart';
import '../theme.dart';

/// Screen 30 — staff schedule + roster (UC-35/66). Store Manager view: the
/// scheduled shifts and the branch roster with PIN status.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late final ScheduleApi _api;
  List<ScheduleShift> _shifts = const [];
  List<StaffRoster> _roster = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = ScheduleApi(context.read<ApiClient>());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final shifts = await _api.list();
      final roster = await _api.roster();
      if (mounted) {
        setState(() {
          _shifts = shifts;
          _roster = roster;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : 'Không tải được lịch làm việc');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrown,
        foregroundColor: Colors.white,
        title: const Text('Lịch làm việc'),
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: Text('Đang tải…'));
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: kDanger)));
    return ListView(
      key: const Key('schedule-view'),
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionHeader('Ca làm việc'),
        if (_shifts.isEmpty) const Text('Chưa có ca nào', style: TextStyle(color: kMuted)),
        for (final s in _shifts) _shiftRow(s),
        const SizedBox(height: 20),
        const _SectionHeader('Nhân sự chi nhánh'),
        for (final r in _roster) _rosterRow(r),
      ],
    );
  }

  Widget _shiftRow(ScheduleShift s) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          key: Key('shift-${s.id}'),
          leading: const Icon(Icons.schedule, color: kBrown),
          title: Row(
            children: [
              Expanded(child: Text(s.employeeName, style: const TextStyle(fontWeight: FontWeight.w600))),
              if (s.crossBranch)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: kGold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Text('Liên chi nhánh', style: TextStyle(color: kBrown, fontSize: 11)),
                ),
            ],
          ),
          subtitle: Text('${_shiftTypeLabel(s.shiftType)} · ${s.shiftStartTime ?? ''}–${s.shiftEndTime ?? ''}'
              '${s.posRegisterId != null ? ' · ${s.posRegisterId}' : ''}'),
          trailing: Text(s.shiftDate, style: const TextStyle(color: kMuted, fontSize: 12)),
        ),
      );

  Widget _rosterRow(StaffRoster r) => ListTile(
        key: Key('roster-${r.userId}'),
        dense: true,
        leading: const Icon(Icons.person_outline, color: kBrown),
        title: Text(r.fullName),
        subtitle: Text('${r.role}${r.employeeId != null ? ' · ${r.employeeId}' : ''}'),
        trailing: Text(
          r.pinLocked ? 'PIN khóa' : (r.pinSet ? 'PIN ✓' : 'Chưa có PIN'),
          style: TextStyle(
            fontSize: 12,
            color: r.pinLocked ? kDanger : (r.pinSet ? kSuccess : kMuted),
          ),
        ),
      );

  String _shiftTypeLabel(String t) => switch (t) {
        'MORNING' => 'Ca sáng',
        'AFTERNOON' => 'Ca chiều',
        'FULL_DAY' => 'Cả ngày',
        _ => t,
      };
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kBrown)),
      );
}
