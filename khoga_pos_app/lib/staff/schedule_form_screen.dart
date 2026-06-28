import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/staff_api.dart';
import '../theme.dart';

/// Screen 36/37 — create or edit a shift. In edit mode the employee and date are
/// fixed (BR-36); create mode picks an employee from the roster.
class ScheduleFormScreen extends StatefulWidget {
  /// When non-null, the form edits this shift (UC-37); otherwise it creates (UC-36).
  final ScheduleShift? existing;
  const ScheduleFormScreen({super.key, this.existing});

  bool get isEdit => existing != null;

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  static const _types = [('MORNING', 'Ca sáng'), ('AFTERNOON', 'Ca chiều'), ('FULL_DAY', 'Cả ngày')];

  late final ScheduleApi _api;
  final _date = TextEditingController();
  final _start = TextEditingController();
  final _end = TextEditingController();
  final _register = TextEditingController();

  List<StaffRoster> _roster = const [];
  String? _employeeId;
  String _type = 'MORNING';
  bool _loadingRoster = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = ScheduleApi(context.read<ApiClient>());
    final e = widget.existing;
    if (e != null) {
      _employeeId = e.employeeId;
      _date.text = e.shiftDate;
      _type = e.shiftType;
      _start.text = e.shiftStartTime ?? '';
      _end.text = e.shiftEndTime ?? '';
      _register.text = e.posRegisterId ?? '';
    } else {
      _start.text = '08:00';
      _end.text = '12:00';
      _loadRoster();
    }
  }

  @override
  void dispose() {
    _date.dispose();
    _start.dispose();
    _end.dispose();
    _register.dispose();
    super.dispose();
  }

  Future<void> _loadRoster() async {
    setState(() => _loadingRoster = true);
    try {
      final r = await _api.roster();
      if (mounted) setState(() => _roster = r);
    } catch (_) {
      // roster optional; employee field just stays empty
    } finally {
      if (mounted) setState(() => _loadingRoster = false);
    }
  }

  Future<void> _submit() async {
    if (!widget.isEdit && _employeeId == null) {
      setState(() => _error = 'Vui lòng chọn nhân viên');
      return;
    }
    if (_date.text.trim().isEmpty || _start.text.trim().isEmpty || _end.text.trim().isEmpty) {
      setState(() => _error = 'Vui lòng nhập ngày và giờ làm');
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      if (widget.isEdit) {
        await _api.update(widget.existing!.id,
            shiftType: _type,
            shiftStartTime: _start.text.trim(),
            shiftEndTime: _end.text.trim(),
            posRegisterId: _register.text.trim());
      } else {
        await _api.create(
            employeeId: _employeeId!,
            shiftDate: _date.text.trim(),
            shiftType: _type,
            shiftStartTime: _start.text.trim(),
            shiftEndTime: _end.text.trim(),
            posRegisterId: _register.text.trim());
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Không kết nối được máy chủ');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBrown,
        foregroundColor: Colors.white,
        title: Text(widget.isEdit ? 'Sửa ca làm' : 'Thêm ca làm'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  Text(_error!, key: const Key('schedule-form-error'), style: const TextStyle(color: kDanger)),
                  const SizedBox(height: 12),
                ],
                _label('Nhân viên *'),
                if (widget.isEdit)
                  Text(widget.existing!.employeeName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))
                else
                  _employeePicker(),
                const SizedBox(height: 16),
                _label('Ngày làm (yyyy-MM-dd) *'),
                TextField(
                  key: const Key('shift-date'),
                  controller: _date,
                  readOnly: widget.isEdit,
                  decoration: const InputDecoration(hintText: '2026-06-29'),
                ),
                const SizedBox(height: 16),
                _label('Loại ca *'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final t in _types)
                      ChoiceChip(
                        key: Key('type-${t.$1}'),
                        label: Text(t.$2),
                        selected: _type == t.$1,
                        onSelected: (_) => setState(() => _type = t.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _timeField('Giờ bắt đầu *', _start, const Key('shift-start'))),
                    const SizedBox(width: 12),
                    Expanded(child: _timeField('Giờ kết thúc *', _end, const Key('shift-end'))),
                  ],
                ),
                const SizedBox(height: 16),
                _label('Máy POS (nếu là thu ngân)'),
                TextField(key: const Key('shift-register'), controller: _register, decoration: const InputDecoration(hintText: 'POS-01')),
                const SizedBox(height: 28),
                ElevatedButton(
                  key: const Key('schedule-save'),
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(widget.isEdit ? 'LƯU CA' : 'TẠO CA'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _employeePicker() {
    if (_loadingRoster) return const Text('Đang tải nhân viên…', style: TextStyle(color: kMuted));
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in _roster)
          ChoiceChip(
            key: Key('emp-${s.userId}'),
            label: Text(s.fullName),
            selected: _employeeId == s.userId,
            onSelected: (_) => setState(() => _employeeId = s.userId),
          ),
      ],
    );
  }

  Widget _timeField(String label, TextEditingController c, Key key) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          TextField(key: key, controller: c, decoration: const InputDecoration(hintText: '08:00')),
        ],
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBrown)),
      );
}
