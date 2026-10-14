import 'package:intl/intl.dart';

import 'package:finance_tracker/features/shared/data/currency.dart';

/// Centralized money formatting. Amounts are stored as integer minor units to
/// avoid floating point drift; formatting and parsing happen only at the edges.
abstract final class MoneyFormatter {
  /// Display symbol, padded with a space when it ends in a letter (`Rs `).
  static String symbolFor(String currencyCode) {
    final symbol = Currency.fromCode(currencyCode).symbol;
    return RegExp(r'[A-Za-z]$').hasMatch(symbol) ? '$symbol ' : symbol;
  }

  /// Formats minor units with grouping, e.g. `A$1,234.56`.
  static String format(
    int minorUnits,
    String currencyCode, {
    String locale = 'en',
    bool signed = false,
  }) {
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: symbolFor(currencyCode),
      decimalDigits: 2,
    );
    final value = minorUnits / 100;
    final text = formatter.format(value.abs());
    if (minorUnits < 0) return '−$text';
    if (signed) return '+$text';
    return text;
  }

  /// Compact form for charts and tight spaces, e.g. `A$1.2K`.
  static String compact(
    int minorUnits,
    String currencyCode, {
    String locale = 'en',
  }) {
    final formatter = NumberFormat.compactCurrency(
      locale: locale,
      symbol: symbolFor(currencyCode),
      decimalDigits: 1,
    );
    final text = formatter.format(minorUnits / 100);
    return minorUnits < 0 ? '−$text' : text;
  }

  /// Parses a user-typed major amount into minor units, or null when invalid.
  static int? tryParseToMinor(String input) {
    final normalized = input.trim().replaceAll(',', '').replaceAll('−', '-');
    if (normalized.isEmpty) return null;
    final value = double.tryParse(normalized);
    if (value == null || !value.isFinite) return null;
    return (value * 100).round();
  }

  /// Converts a signed minor-unit total into a display sign prefix.
  static String signPrefix(int minorUnits) => minorUnits < 0 ? '−' : '';

  /// Plain decimal representation without symbol or grouping, for editing.
  /// Whole amounts drop the decimal part so fields stay tidy.
  static String decimal(int minorUnits) {
    final negative = minorUnits < 0;
    final absolute = minorUnits.abs();
    final major = absolute ~/ 100;
    final minor = absolute % 100;
    final text =
        minor == 0 ? '$major' : '$major.${minor.toString().padLeft(2, '0')}';
    return negative ? '-$text' : text;
  }

  /// Plain number with grouping, without currency symbol, e.g. `6,240.50` or `4,180`.
  static String formatRaw(int minorUnits) {
    final major = minorUnits / 100.0;
    if (minorUnits % 100 == 0) {
      return NumberFormat('#,##0').format(major);
    }
    return NumberFormat('#,##0.00').format(major);
  }
}
