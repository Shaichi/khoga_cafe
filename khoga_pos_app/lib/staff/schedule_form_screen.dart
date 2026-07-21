import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/staff_api.dart';

// Figma Colors
const Color cBgWhite = Color(0xFFFFFFFF);
const Color cBorderLight = Color(0xFFEADDD3);
const Color cTextDark = Color(0xFF2C1A11);
const Color cTextMuted = Color(0xFF8C766C);
const Color cBrownDark = Color(0xFF3D2314);
const Color cPrimary = Color(0xFF5C3826);
const Color cDanger = Color(0xFFC62828);

class ScheduleFormScreen extends StatefulWidget {
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
  
  final Set<String> _selectedTypes = {'MORNING'};

  bool _loadingRoster = false;
  bool _submitting = false;
  String? _error;

  bool get _isBarista {
    if (widget.isEdit) {
      return widget.existing!.role.toLowerCase().contains('pha chế') || widget.existing!.role.toLowerCase().contains('barista');
    }
    for (final r in _roster) {
      if (r.userId == _employeeId) {
        return r.role.toLowerCase().contains('pha chế') || r.role.toLowerCase().contains('barista');
      }
    }
    return false;
  }


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

  Future<void> _submit() async {
    if (!widget.isEdit && _employeeId == null) {
      setState(() => _error = 'Vui lòng chọn nhân viên');
      return;
    }
    if (_date.text.trim().isEmpty) {
      setState(() => _error = 'Vui lòng nhập ngày làm việc');
      return;
    }
    if (_selectedTypes.isEmpty) {
      setState(() => _error = 'Vui lòng chọn ca làm việc');
      return;
    }
    if (!_isBarista && _register.text.trim().isEmpty) {
      setState(() => _error = 'Vui lòng chọn máy POS phân bổ');
      return;
    }
    
    if (!widget.isEdit) {
      try {
        final parts = _date.text.trim().split('-');
        final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        if (d.isBefore(today)) {
          setState(() => _error = 'Không thể phân ca làm việc trong quá khứ');
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
        final type = _selectedTypes.first;
        await _api.update(widget.existing!.id,
            shiftType: type,
            shiftStartTime: _start.text.trim(),
            shiftEndTime: _end.text.trim(),
            posRegisterId: _isBarista ? null : _register.text.trim());
      } else {
        final type = _selectedTypes.first;
        await _api.create(
          employeeId: _employeeId!,
          shiftDate: _date.text.trim(),
          shiftType: type,
          shiftStartTime: _start.text.trim(),
          shiftEndTime: _end.text.trim(),
          posRegisterId: _isBarista ? null : _register.text.trim()
        );
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
        title: const Text('Xác nhận', style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, color: cBrownDark)),
        content: const Text('Bạn có chắc chắn muốn xóa ca làm này?', style: TextStyle(fontFamily: 'Segoe UI')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('HỦY', style: TextStyle(color: cBrownDark, fontFamily: 'Segoe UI'))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('XÓA', style: TextStyle(color: cDanger, fontFamily: 'Segoe UI'))),
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

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: cBgWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: cBorderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: cBrownDark),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: cBorderLight),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cBrownDark, fontFamily: 'Segoe UI')),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBgWhite,
      appBar: AppBar(
        backgroundColor: cBgWhite,
        foregroundColor: cBrownDark,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: cTextMuted),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.isEdit ? 'Điều Chỉnh Ca' : 'Phân Ca Mới',
          style: const TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 22, color: cBrownDark),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Text(_error!, key: const Key('schedule-form-error'), style: const TextStyle(color: cDanger, fontFamily: 'Segoe UI')),
                const SizedBox(height: 12),
              ],
              
              if (widget.isEdit) ...[
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontFamily: 'Segoe UI', fontSize: 16, color: cTextDark),
                    children: [
                      const TextSpan(text: 'Nhân viên: ', style: TextStyle(fontWeight: FontWeight.bold, color: cBrownDark)),
                      TextSpan(text: widget.existing!.employeeName),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontFamily: 'Segoe UI', fontSize: 16, color: cTextDark),
                    children: [
                      const TextSpan(text: 'Ngày: ', style: TextStyle(fontWeight: FontWeight.bold, color: cBrownDark)),
                      TextSpan(text: _date.text),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                _label('Nhân viên *'),
                if (_loadingRoster)
                  TextFormField(
                    enabled: false,
                    decoration: _inputDecoration().copyWith(hintText: 'Đang tải...'),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _employeeId,
                    decoration: _inputDecoration(),
                    icon: const Icon(Icons.keyboard_arrow_down, color: cTextMuted),
                    items: _roster.map((s) => DropdownMenuItem(
                      value: s.userId,
                      child: Text(s.fullName, style: const TextStyle(fontFamily: 'Segoe UI', color: cBrownDark)),
                    )).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _employeeId = v);
                    },
                  ),
                const SizedBox(height: 20),

                _label('Ngày làm việc *'),
                TextFormField(
                  key: const Key('shift-date'),
                  controller: _date,
                  readOnly: true, // Typically chosen from previous screen
                  decoration: _inputDecoration(),
                  style: const TextStyle(fontFamily: 'Segoe UI', color: cTextDark),
                ),
                const SizedBox(height: 20),
              ],
              
              _label(widget.isEdit ? 'Ca làm việc' : 'Ca làm việc *'),
              DropdownButtonFormField<String>(
                value: _selectedTypes.isEmpty ? null : _selectedTypes.first,
                decoration: _inputDecoration(),
                icon: const Icon(Icons.keyboard_arrow_down, color: cTextMuted),
                items: _allTypes.map((t) => DropdownMenuItem(
                  value: t.$1,
                  child: Text(t.$2, style: const TextStyle(fontFamily: 'Segoe UI', color: cBrownDark)),
                )).toList(),
                onChanged: widget.isPast ? null : (v) {
                  if (v != null) {
                    setState(() {
                      _selectedTypes.clear();
                      _selectedTypes.add(v);
                      if (v == 'MORNING') {
                        _start.text = '08:00';
                        _end.text = '12:00';
                      } else if (v == 'AFTERNOON') {
                        _start.text = '12:00';
                        _end.text = '18:00';
                      } else if (v == 'FULL_DAY') {
                        _start.text = '08:00';
                        _end.text = '18:00';
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              if (!_isBarista) ...[
                _label(widget.isEdit ? 'Đăng ký' : 'Máy POS phân bổ *'),
                DropdownButtonFormField<String>(
                  key: const Key('shift-register'),
                  value: _register.text.isEmpty ? null : _register.text,
                  decoration: _inputDecoration(),
                  icon: const Icon(Icons.keyboard_arrow_down, color: cTextMuted),
                  items: const [
                    DropdownMenuItem(value: 'REG-01', child: Text('REG-01')),
                    DropdownMenuItem(value: 'REG-02', child: Text('REG-02')),
                    DropdownMenuItem(value: 'REG-03', child: Text('REG-03')),
                  ],
                  onChanged: widget.isPast ? null : (val) {
                    if (val != null) setState(() => _register.text = val);
                  },
                ),
                const SizedBox(height: 20),
              ],
              
              if (widget.isPast)
                const Center(
                  child: Text(
                    'Ca làm việc trong quá khứ chỉ có thể xem, không thể sửa đổi hoặc xóa.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cTextMuted, fontStyle: FontStyle.italic, fontFamily: 'Segoe UI'),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: cBgWhite,
          border: Border(top: BorderSide(color: Colors.transparent)),
        ),
        child: widget.isEdit 
          ? (widget.isPast 
              ? const SizedBox.shrink()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            key: const Key('schedule-save'),
                            onPressed: _submitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cBrownDark,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: _submitting
                                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('LƯU', style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _submitting ? null : _delete,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              side: const BorderSide(color: cBorderLight),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('XÓA', style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, color: cDanger, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        side: const BorderSide(color: cBorderLight),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('HỦY', style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, color: cBrownDark, fontSize: 16)),
                    ),
                  ],
                ))
          : Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: cBorderLight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('HỦY', style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, color: cBrownDark, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    key: const Key('schedule-save'),
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cBrownDark,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('PHÂN CA', style: TextStyle(fontFamily: 'Segoe UI', fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
