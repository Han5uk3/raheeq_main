import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class Formatters {
  static final Map<String, NumberFormat> _priceFormats = {};

  /// Locales used for formatting. Both keep Western digits: intl follows CLDR,
  /// where `ar` uses Latin digits and only translates the words, which is
  /// exactly what the app wants — Arabic month names and ص/م, never ٠١٢.
  static const String arabicLocale = 'ar';
  static const String englishLocale = 'en_US';

  /// The full date, e.g. `20 June 2026` / `20 يونيو 2026`.
  static const String _datePattern = 'd MMMM yyyy';

  /// The weekday name on its own, e.g. `Saturday` / `السبت`.
  static const String _weekdayPattern = 'EEEE';

  /// The clock time, e.g. `12:30 PM` / `12:30 م`.
  static const String _timePattern = 'h:mm a';

  /// Month and year only, e.g. `June 2026` / `يونيو 2026`.
  static const String _monthYearPattern = 'MMMM yyyy';

  /// True when the app is currently running in Arabic.
  static bool isArabic(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar';

  /// The intl locale name for the app's language.
  static String localeOf(BuildContext context) =>
      isArabic(context) ? arabicLocale : englishLocale;

  /// Formats a monetary amount with imperial thousands separators
  /// (e.g. 1,234,567.89).
  ///
  /// The locale is pinned to en_US so the grouping stays comma based and the
  /// digits stay Western in both languages.
  ///
  /// [decimals] defaults to none for an amount that has no halalas to show —
  /// whole, or fractional only below what two decimals would render — and 2
  /// otherwise, so `100` and `100.00` both read as `100` while `100.50` keeps
  /// its decimals. Pass it explicitly when a screen always wants the same
  /// number of decimals.
  static String formatPrice(num value, {int? decimals}) {
    final digits = decimals ?? (_hasVisibleFraction(value) ? 2 : 0);
    final format = _priceFormats.putIfAbsent(
      '$digits',
      () => NumberFormat.decimalPatternDigits(
        locale: englishLocale,
        decimalDigits: digits,
      ),
    );
    return format.format(value);
  }

  /// Whether [value] still has a fractional part once rounded to the two
  /// decimals a price is rendered with. Amounts like 100.004 round to 100.00,
  /// which is a whole amount as far as the user can see.
  static bool _hasVisibleFraction(num value) {
    final rounded = (value.toDouble() * 100).roundToDouble() / 100;
    return rounded != rounded.truncateToDouble();
  }

  /// `20 June 2026` in English, `20 يونيو 2026` in Arabic.
  static String formatDate(BuildContext context, DateTime date) =>
      DateFormat(_datePattern, localeOf(context)).format(date.toLocal());

  /// `Saturday, 20 June 2026` in English, `السبت، 20 يونيو 2026` in Arabic
  /// (the comma is the Arabic one, U+060C).
  ///
  /// The weekday is formatted separately rather than folded into
  /// [_datePattern] because a comma inside the pattern would stay Latin in
  /// Arabic.
  static String formatDateWithWeekday(BuildContext context, DateTime date) {
    final separator = isArabic(context) ? '، ' : ', ';
    final weekday = DateFormat(
      _weekdayPattern,
      localeOf(context),
    ).format(date.toLocal());
    return '$weekday$separator${formatDate(context, date)}';
  }

  /// `12:30 PM` in English, `12:30 م` in Arabic.
  static String formatTime(BuildContext context, DateTime date) =>
      DateFormat(_timePattern, localeOf(context)).format(date.toLocal());

  /// `20 June 2026, 12:30 PM` in English, `20 يونيو 2026، 12:30 م` in Arabic
  /// (the comma is the Arabic one, U+060C).
  static String formatDateTime(BuildContext context, DateTime date) {
    final separator = isArabic(context) ? '، ' : ', ';
    return '${formatDate(context, date)}$separator${formatTime(context, date)}';
  }

  /// `June 2026` in English, `يونيو 2026` in Arabic.
  static String formatMonthYear(BuildContext context, DateTime date) =>
      DateFormat(_monthYearPattern, localeOf(context)).format(date.toLocal());

  static String formatCount(num value) {
    if (value >= 1000000000) {
      return '${_formatDouble(value / 1000000000)}B';
    } else if (value >= 1000000) {
      return '${_formatDouble(value / 1000000)}M';
    } else if (value >= 1000) {
      return '${_formatDouble(value / 1000)}K';
    } else {
      if (value is int || value == value.toInt()) {
        return value.toInt().toString();
      }
      return _formatDouble(value.toDouble());
    }
  }

  static String _formatDouble(double value) {
    String str = value.toStringAsFixed(2);
    if (str.endsWith('.00')) {
      return str.substring(0, str.length - 3);
    } else if (str.endsWith('0') && str.contains('.')) {
      return str.substring(0, str.length - 1);
    }
    return str;
  }
}
