import 'package:intl/intl.dart';

class Formatters {
  static final _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  static final _currencyDecimal = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );
  static final _date = DateFormat('dd MMM yyyy');
  static final _monthYear = DateFormat('MMM yyyy');
  static final _shortDate = DateFormat('dd MMM');

  static String currency(double amount) => _currency.format(amount);
  static String currencyDecimal(double amount) =>
      _currencyDecimal.format(amount);
  static String date(DateTime dt) => _date.format(dt);
  static String monthYear(DateTime dt) => _monthYear.format(dt);
  static String shortDate(DateTime dt) => _shortDate.format(dt);

  static String tenure(int months) {
    if (months < 12) return '$months months';
    final years = months ~/ 12;
    final rem = months % 12;
    if (rem == 0) return '$years ${years == 1 ? 'year' : 'years'}';
    return '$years yr $rem mo';
  }

  static String percentage(double value) =>
      '${value.toStringAsFixed(1)}%';

  /// Compact currency for tables — e.g. ₹1.2L, ₹45K
  static String compactCurrency(double amount) {
    if (amount >= 10000000) return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return '₹${amount.toStringAsFixed(0)}';
  }
}
