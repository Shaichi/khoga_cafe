/// Formats a VND amount with '.' thousands separators, e.g. 30000 -> "30.000".
String formatVnd(num amount) {
  final digits = amount.round().abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  final sign = amount < 0 ? '-' : '';
  return '$sign$buf';
}

/// Formats an ISO 8601 string to a human-readable date and time.
/// Example: "2023-10-27T10:30:00Z" -> "27/10/2023 17:30"
String formatDateTime(String? iso8601) {
  if (iso8601 == null || iso8601.isEmpty) return '';
  try {
    final dt = DateTime.parse(iso8601).toLocal();
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  } catch (_) {
    return iso8601;
  }
}

