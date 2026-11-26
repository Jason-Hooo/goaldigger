/// Pure formatting / parsing helpers shared by every feature.
abstract final class Formatters {
  static final RegExp _thousands = RegExp(r'\B(?=(\d{3})+(?!\d))');

  /// Whole-number currency value with thousands separators: `1,234`.
  static String money(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(_thousands, (_) => ',');
  }

  /// Two-decimal value with thousands separators, dropping a `.00` suffix:
  /// `1,234` / `1,234.50`.
  static String amount(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final integer = parts[0].replaceAllMapped(_thousands, (_) => ',');
    return parts[1] == '00' ? integer : '$integer.${parts[1]}';
  }

  /// Plain editable representation for text fields: `1234` / `1234.5`.
  static String editable(double value) {
    return value == value.truncateToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }

  /// `2026/05/09`
  static String date(DateTime value) {
    return '${value.year}/${_twoDigits(value.month)}/${_twoDigits(value.day)}';
  }

  /// `2026/5/9`
  static String shortDate(DateTime value) {
    return '${value.year}/${value.month}/${value.day}';
  }

  /// `5/9`
  static String monthDay(DateTime value) => '${value.month}/${value.day}';

  /// `2026/05`
  static String yearMonth(DateTime value) {
    return '${value.year}/${_twoDigits(value.month)}';
  }

  /// `2026-05-09 13:45:12`
  static String dateTime(DateTime value) => value.toString().split('.').first;

  /// ISO date without time, as expected by the backend: `2026-05-09`.
  static String isoDate(DateTime value) {
    return value.toIso8601String().split('T').first;
  }

  /// Parses user input such as `1,234.5`; returns `null` when invalid.
  static double? parseAmount(String? input) {
    return double.tryParse((input ?? '').trim().replaceAll(',', ''));
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
