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

/// Formats a DateTime as DD/MM/YYYY.
String formatDate(DateTime d) {
  final dStr = d.day.toString().padLeft(2, '0');
  final mStr = d.month.toString().padLeft(2, '0');
  return '$dStr/$mStr/${d.year}';
}
