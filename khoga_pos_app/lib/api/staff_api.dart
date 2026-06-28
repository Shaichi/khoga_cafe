import 'api_client.dart';
import 'models.dart';

/// Staff scheduling + roster (UC-35/66). Store Manager scope on the backend.
class ScheduleApi {
  final ApiClient _client;
  ScheduleApi(this._client);

  /// Scheduled shifts (UC-35); defaults to the current week when no range given.
  Future<List<ScheduleShift>> list({String? from, String? to}) async {
    final q = <String>[];
    if (from != null) q.add('from=$from');
    if (to != null) q.add('to=$to');
    final data = await _client.get('/schedules${q.isEmpty ? '' : '?${q.join('&')}'}');
    return (data as List).map((j) => ScheduleShift.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Branch staff roster (UC-66).
  Future<List<StaffRoster>> roster() async {
    final data = await _client.get('/staff');
    return (data as List).map((j) => StaffRoster.fromJson(j as Map<String, dynamic>)).toList();
  }
}

/// Attendance terminal (UC-67). Operated at the branch by any staff; the PIN
/// identifies the employee.
class AttendanceApi {
  final ApiClient _client;
  AttendanceApi(this._client);

  Future<Attendance> checkIn(String pin, {String? photoUrl}) async {
    final data = await _client.post('/attendance/check-in', {
      'pin': pin,
      if (photoUrl != null && photoUrl.isNotEmpty) 'photoUrl': photoUrl,
    });
    return Attendance.fromJson(data as Map<String, dynamic>);
  }

  Future<Attendance> checkOut(String pin) async {
    final data = await _client.post('/attendance/check-out', {'pin': pin});
    return Attendance.fromJson(data as Map<String, dynamic>);
  }
}
