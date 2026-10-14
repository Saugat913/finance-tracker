import 'package:intl/intl.dart';

/// Centralized, locale-aware date formatting.
abstract final class DateFormatter {
  static String monthYear(DateTime date, {String? locale}) =>
      DateFormat.yMMMM(locale).format(date);

  static String monthShort(DateTime date, {String? locale}) =>
      DateFormat.MMM(locale).format(date);

  static String day(DateTime date, {String? locale}) =>
      DateFormat.d(locale).format(date);

  static String numeric(DateTime date, {String? locale}) =>
      DateFormat.yMd(locale).format(date);

  static String weekdayDate(DateTime date, {String? locale}) =>
      DateFormat.MMMEd(locale).format(date);

  static String time(DateTime date, {String? locale}) =>
      DateFormat.jm(locale).format(date);

  static String monthDayTime(DateTime date, {String? locale}) =>
      DateFormat.MMMd(locale).add_jm().format(date);

  /// Human-friendly relative label such as `Today`, `Yesterday`, `in 3 days`.
  static String relative(DateTime date, {DateTime? now}) {
    final reference = AppDate.dateOnly(now ?? DateTime.now());
    final target = AppDate.dateOnly(date);
    final days = target.difference(reference).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    if (days == -1) return 'Yesterday';
    if (days > 1 && days < 7) return 'In $days days';
    if (days < -1 && days > -7) return '${-days} days ago';
    return numeric(date);
  }
}

/// Small date helpers shared across features.
abstract final class AppDate {
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month);

  static DateTime endOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);

  static int daysInMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0).day;

  static List<DateTime> monthGrid(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final offset = first.weekday - DateTime.monday;
    final start = first.subtract(Duration(days: offset));
    return List.generate(42, (index) => start.add(Duration(days: index)));
  }

  static String header(DateTime date) => DateFormat('EEEE, d MMM').format(date);
  static String short(DateTime date) => DateFormat('d MMM').format(date);
  static String weekday(DateTime date) => DateFormat('EEE').format(date);
  static String weekdayDay(DateTime date) => DateFormat('EEE d').format(date);
  static String monthYear(DateTime date) => DateFormat('MMMM y').format(date);
  static String timeOnly(DateTime date) => DateFormat('h:mm a').format(date).toLowerCase();
}
