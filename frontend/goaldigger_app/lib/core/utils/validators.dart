import 'formatters.dart';

/// Reusable form field validators returning a localized error or `null`.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+');

  static bool isValidEmail(String input) => _email.hasMatch(input);

  static String? Function(String?) required(String message) {
    return (value) => (value ?? '').trim().isEmpty ? message : null;
  }

  /// Requires a number strictly greater than zero.
  static String? positiveAmount(String? value, {String? message}) {
    final amount = Formatters.parseAmount(value);
    if (amount == null) {
      return '請輸入數字';
    }
    if (amount <= 0) {
      return message ?? '金額必須大於 0';
    }
    return null;
  }

  /// Requires any number.
  static String? number(String? value) {
    return Formatters.parseAmount(value) == null ? '請輸入數字' : null;
  }

  /// Requires a number greater than or equal to zero.
  static String? nonNegativeAmount(String? value) {
    final amount = Formatters.parseAmount(value);
    if (amount == null) {
      return '請輸入數字';
    }
    if (amount < 0) {
      return '金額不能為負數';
    }
    return null;
  }
}
