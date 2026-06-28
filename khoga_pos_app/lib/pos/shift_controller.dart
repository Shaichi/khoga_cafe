import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../api/shift_api.dart';

/// Tracks the cashier's active shift. The POS is gated on [hasOpenShift].
class ShiftController extends ChangeNotifier {
  final ShiftApi _api;
  ShiftController(this._api);

  Shift? _active;
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  Shift? get active => _active;
  bool get loading => _loading;
  bool get loaded => _loaded;
  bool get hasOpenShift => _active != null;
  String? get error => _error;

  Future<void> loadActive() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _active = await _api.getActive();
    } catch (e) {
      _error = e is ApiException ? e.message : 'Không tải được thông tin ca';
    } finally {
      _loading = false;
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> open(String posRegisterId, num startingCash) async {
    _active = await _api.open(posRegisterId, startingCash);
    notifyListeners();
  }

  /// Closes the active shift, clears it (so the gate falls back to open-shift), and
  /// returns the Z-report. Throws [ApiException] if there is no shift to close.
  Future<ZReport> close(num closingCash) async {
    final shift = _active;
    if (shift == null) throw ApiException('Không có ca đang mở để đóng');
    final report = await _api.close(shift.id, closingCash);
    _active = null;
    notifyListeners();
    return report;
  }

  void reset() {
    _active = null;
    _loaded = false;
    _error = null;
  }
}
