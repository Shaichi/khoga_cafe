import 'package:flutter/services.dart';

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

/// Formatter for text inputs to automatically add '.' thousands separators.
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Handle backspace properly if deleting a separator
    if (oldValue.text.length > newValue.text.length) {
      if (oldValue.text.substring(newValue.selection.start, newValue.selection.start + 1) == '.') {
        // We'll let the user delete the dot, but we need to reformat everything anyway
      }
    }

    // Clean up non-digits
    final numericString = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericString.isEmpty) {
      return newValue.copyWith(text: '', selection: const TextSelection.collapsed(offset: 0));
    }

    // Format with dots
    final numValue = int.parse(numericString);
    final formattedString = formatVnd(numValue);

    // Calculate new cursor position
    int selectionIndex = newValue.selection.end;
    
    // We can simply set the cursor at the end for simplicity, 
    // or calculate it based on dots added. For currency input, 
    // usually users type at the end.
    // A robust cursor position calculation:
    int diff = formattedString.length - newValue.text.length;
    selectionIndex += diff;
    
    if (selectionIndex > formattedString.length) {
      selectionIndex = formattedString.length;
    } else if (selectionIndex < 0) {
      selectionIndex = 0;
    }

    return TextEditingValue(
      text: formattedString,
      selection: TextSelection.collapsed(offset: formattedString.length), // Always put cursor at end for simplicity
    );
  }
}
