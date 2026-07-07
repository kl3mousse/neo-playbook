import 'package:flutter/services.dart';

/// A [TextInputFormatter] that normalises price input:
///
/// - Replaces `,` with `.` so both decimal separators are accepted.
/// - Strips any character that is not a digit or `.`.
/// - Permits at most one decimal separator.
/// - Limits the fractional part to two digits (cents precision).
///
/// Pair with `keyboardType: TextInputType.numberWithOptions(decimal: true)`
/// and parse the result with [parsePrice].
class PriceInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Normalise separator and strip invalid characters.
    var text = newValue.text.replaceAll(',', '.').replaceAll(RegExp(r'[^\d.]'), '');

    // Collapse multiple dots: keep only the first one.
    final dotIndex = text.indexOf('.');
    if (dotIndex != -1) {
      final afterDot = text.substring(dotIndex + 1).replaceAll('.', '');
      // Truncate fractional part to 2 digits.
      final cents = afterDot.length > 2 ? afterDot.substring(0, 2) : afterDot;
      text = '${text.substring(0, dotIndex)}.$cents';
    }

    // Keep the cursor within bounds.
    final offset = newValue.selection.extentOffset.clamp(0, text.length);
    return newValue.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

/// Parse a price string that may use either `.` or `,` as the decimal
/// separator. Returns `null` for empty or unparseable input.
double? parsePrice(String text) {
  final normalised = text.trim().replaceAll(',', '.');
  if (normalised.isEmpty) return null;
  return double.tryParse(normalised);
}
