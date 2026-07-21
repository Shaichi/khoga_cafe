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
  final String? defaultDate;
  
  const ScheduleFormScreen({super.key, this.existing, this.defaultDate});

  bool get isEdit => existing != null;
  
  bool get isPast {
    if (existing == null) return false;
    try {
      final parts = existing!.shiftDate.split('-');
      final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return d.isBefore(today);
    } catch (_) {
      return false;
    }
  }

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  static const _allTypes = [('MORNING', 'Ca sáng'), ('AFTERNOON', 'Ca chiều'), ('FULL_DAY', 'Cả ngày')];

  late final ScheduleApi _api;
  final _date = TextEditingController();
  final _start = TextEditingController();
  final _end = TextEditingController();
  final _register = TextEditingController();

  List<StaffRoster> _roster = const [];
  String? _employeeId;
  
  // Mảng lưu các ca được chọn
  final Set<String> _selectedTypes = {'MORNING'};
  
  // Phạm vi phân ca
  String _scope = 'DAILY'; // DAILY, WEEKLY, MONTHLY

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
      _selectedTypes.clear();
      _selectedTypes.add(e.shiftType);
      _start.text = e.shiftStartTime ?? '';
      _end.text = e.shiftEndTime ?? '';
      _register.text = e.posRegisterId ?? '';
    } else {
      _date.text = widget.defaultDate ?? '';
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
    } finally {
      if (mounted) setState(() => _loadingRoster = false);
    }
  }

  // Lấy danh sách các ngày để rải ca
  List<String> _getDatesForScope(String baseDateStr, String scope) {
    if (baseDateStr.isEmpty) return [];
    try {
      final parts = baseDateStr.split('-');
      final baseDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

      if (scope == 'DAILY') {
        return [baseDateStr];
      } else if (scope == 'WEEKLY') {
        // Rải ca cho tuần tiếp theo (từ Thứ 2 tuần sau)
        final nextMonday = baseDate.add(Duration(days: 8 - baseDate.weekday));
        List<String> dates = [];
        for (int i = 0; i < 7; i++) {
          final d = nextMonday.add(Duration(days: i));
          dates.add('${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
        }
        return dates;
      } else if (scope == 'MONTHLY') {
        // All days in the month
        final lastDay = DateTime(baseDate.year, baseDate.month + 1, 0).day;
        List<String> dates = [];
        for (int i = 1; i <= lastDay; i++) {
          dates.add('${baseDate.year}-${baseDate.month.toString().padLeft(2, '0')}-${i.toString().padLeft(2, '0')}');
        }
        return dates;
      }
    } catch (_) {}
    return [baseDateStr];
  }

  Future<void> _submit() async {
    if (!widget.isEdit && _employeeId == null) {
      setState(() => _error = 'Vui lòng chọn nhân viên');
      return;
    }
    if (_date.text.trim().isEmpty) {
      setState(() => _error = 'Vui lòng nhập ngày bắt đầu');
      return;
    }
    if (_selectedTypes.isEmpty) {
      setState(() => _error = 'Vui lòng chọn loại ca');
      return;
    }
    
    if (!widget.isEdit) {
      try {
        final parts = _date.text.trim().split('-');
        final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        if (d.isBefore(today)) {
          setState(() => _error = 'Không thể thêm ca làm việc trong quá khứ');
          return;
        }
      } catch (_) {}
    }

    setState(() {
      _error = null;
      _submitting = true;
    });

    try {
      if (widget.isEdit) {
        // Update a single shift
        final type = _selectedTypes.first; // Edit mode can only select 1 type visually or we just take the first
        await _api.update(widget.existing!.id,
            shiftType: type,
            shiftStartTime: _start.text.trim(),
            shiftEndTime: _end.text.trim(),
            posRegisterId: _register.text.trim());
      } else {
        // Create multiple shifts based on scope and selected types
        final dates = _getDatesForScope(_date.text.trim(), _scope);
        
        List<Future> futures = [];
        for (final d in dates) {
          for (final type in _selectedTypes) {
            futures.add(_api.create(
              employeeId: _employeeId!,
              shiftDate: d,
              shiftType: type,
              shiftStartTime: _start.text.trim(),
              shiftEndTime: _end.text.trim(),
              posRegisterId: _register.text.trim()
            ));
          }
        }
        await Future.wait(futures);
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

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc chắn muốn xóa ca làm này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('HỦY')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('XÓA', style: TextStyle(color: kDanger))),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() {
      _error = null;
      _submitting = true;
    });

    try {
      await _api.delete(widget.existing!.id);
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
                
                if (!widget.isEdit) ...[
                  _label('Phạm vi áp dụng (Rải ca) *'),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Trong ngày'),
                        selected: _scope == 'DAILY',
                        onSelected: (_) => setState(() => _scope = 'DAILY'),
                      ),
                      ChoiceChip(
                        label: const Text('Cả tuần'),
                        selected: _scope == 'WEEKLY',
                        onSelected: (_) => setState(() => _scope = 'WEEKLY'),
                      ),
                      ChoiceChip(
                        label: const Text('Cả tháng'),
                        selected: _scope == 'MONTHLY',
                        onSelected: (_) => setState(() => _scope = 'MONTHLY'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                _label(widget.isEdit ? 'Ngày làm *' : 'Ngày bắt đầu / Ngày chuẩn *'),
                TextField(
                  key: const Key('shift-date'),
                  controller: _date,
                  readOnly: widget.isEdit,
                  decoration: const InputDecoration(hintText: '2026-06-29'),
                ),
                const SizedBox(height: 16),
                
                _label('Loại ca *'),
                ..._allTypes.map((t) {
                  return RadioListTile<String>(
                    key: Key('type-${t.$1}'),
                    title: Text(t.$2),
                    value: t.$1,
                    groupValue: _selectedTypes.isEmpty ? null : _selectedTypes.first,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onChanged: widget.isPast ? null : (val) {
                      if (val != null) {
                        setState(() {
                          _selectedTypes.clear();
                          _selectedTypes.add(val);
                          if (val == 'MORNING') {
                            _start.text = '08:00';
                            _end.text = '12:00';
                          } else if (val == 'AFTERNOON') {
                            _start.text = '12:00';
                            _end.text = '18:00';
                          } else if (val == 'FULL_DAY') {
                            _start.text = '08:00';
                            _end.text = '18:00';
                          }
                        });
                      }
                    },
                  );
                }),
                const SizedBox(height: 16),
                _label('Máy POS (nếu là thu ngân)'),
                DropdownButtonFormField<String>(
                  key: const Key('shift-register'),
                  value: _register.text.isEmpty ? null : _register.text,
                  decoration: InputDecoration(
                    hintText: 'Chọn máy POS',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: kBorder),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'POS-01', child: Text('POS-01')),
                    DropdownMenuItem(value: 'POS-02', child: Text('POS-02')),
                    DropdownMenuItem(value: 'POS-03', child: Text('POS-03')),
                  ],
                  onChanged: widget.isPast ? null : (val) {
                    if (val != null) setState(() => _register.text = val);
                  },
                ),
                const SizedBox(height: 28),
                if (widget.isPast) ...[
                  const Center(
                    child: Text('Ca làm việc trong quá khứ chỉ có thể xem, không thể sửa đổi hoặc xóa.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: kMuted, fontStyle: FontStyle.italic)),
                  ),
                ] else if (widget.isEdit) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _submitting ? null : _delete,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kDanger,
                            side: const BorderSide(color: kDanger),
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: const Text('XÓA CA'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          key: const Key('schedule-save'),
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kBrown,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: _submitting
                              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('LƯU CA'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  ElevatedButton(
                    key: const Key('schedule-save'),
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBrown,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: _submitting
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('TẠO CA'),
                  ),
                ],
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

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBrown)),
  );
}
