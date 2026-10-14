import 'package:finance_tracker/core/database/app_database.dart';

/// A supported currency. Codes are ISO-4217 three-letter strings; amounts are
/// always stored as integer minor units.
class Currency {
  const Currency(this.code, this.name, this.symbol);

  final String code;
  final String name;
  final String symbol;

  static const supported = <Currency>[
    Currency('AUD', 'Australian dollar', r'A$'),
    Currency('NPR', 'Nepali rupee', 'Rs'),
    Currency('USD', 'US dollar', r'US$'),
    Currency('EUR', 'Euro', '€'),
    Currency('GBP', 'Pound sterling', '£'),
    Currency('INR', 'Indian rupee', '₹'),
  ];

  static Currency fromCode(String code) => supported.firstWhere(
    (currency) => currency.code == code.toUpperCase(),
    orElse: () => Currency(code.toUpperCase(), code.toUpperCase(), code),
  );
}

/// A conversion quote. The stored value is the quote amount per one base unit,
/// scaled by [scale] to preserve precision without floating point.
class ExchangeRateQuote {
  const ExchangeRateQuote({
    required this.baseCode,
    required this.quoteCode,
    required this.rateScaled,
  });

  static const int scale = 1000000;

  final String baseCode;
  final String quoteCode;
  final int rateScaled;

  double get rate => rateScaled / scale;

  factory ExchangeRateQuote.fromRow(ExchangeRate row) => ExchangeRateQuote(
    baseCode: row.baseCode,
    quoteCode: row.quoteCode,
    rateScaled: row.rateScaled,
  );
}

/// Converts amounts between currencies using stored quotes, falling back to an
/// identity conversion when currencies match or a rate is missing.
class CurrencyConverter {
  CurrencyConverter(Iterable<ExchangeRateQuote> quotes)
    : _quotes = {
        for (final quote in quotes)
          '${quote.baseCode}>${quote.quoteCode}': quote,
      };

  final Map<String, ExchangeRateQuote> _quotes;

  /// Converts [minorUnits] from [from] to [to]. Returns the input unchanged
  /// when no rate is available, so callers can still show a raw value.
  int convert(int minorUnits, String from, String to) {
    final fromUpper = from.toUpperCase();
    final toUpper = to.toUpperCase();
    if (fromUpper == toUpper) return minorUnits;

    final direct = _quotes['$fromUpper>$toUpper'];
    if (direct != null) {
      return (minorUnits * direct.rateScaled / ExchangeRateQuote.scale).round();
    }

    final inverse = _quotes['$toUpper>$fromUpper'];
    if (inverse != null && inverse.rateScaled != 0) {
      return (minorUnits * ExchangeRateQuote.scale / inverse.rateScaled)
          .round();
    }

    return minorUnits;
  }

  bool hasRate(String from, String to) {
    if (from.toUpperCase() == to.toUpperCase()) return true;
    return _quotes.containsKey('${from.toUpperCase()}>${to.toUpperCase()}') ||
        _quotes.containsKey('${to.toUpperCase()}>${from.toUpperCase()}');
  }
}
