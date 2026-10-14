import 'package:flutter/foundation.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/features/plan/data/forecast_engine.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';

enum CalendarItemType { shift, bill, goal }

class CalendarItem {
  const CalendarItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.amountMinor,
    required this.currencyCode,
    this.isIncome = false,
  });

  final String id;
  final CalendarItemType type;
  final String title;
  final String subtitle;
  final DateTime date;
  final int amountMinor;
  final String currencyCode;
  final bool isIncome;
}

class CalendarViewModel extends ChangeNotifier {
  CalendarViewModel({required this.financeStore}) {
    financeStore.addListener(_onStoreChanged);
  }

  final FinanceStore financeStore;

  DateTime _selectedDate = AppDate.dateOnly(DateTime.now());
  DateTime get selectedDate => _selectedDate;
  String get baseCurrency => financeStore.baseCurrency;

  void _onStoreChanged() {
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = AppDate.dateOnly(date);
    notifyListeners();
  }

  /// 7-day strip centered around the selected date or current week
  List<DateTime> get weekStrip {
    final today = AppDate.dateOnly(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return [for (var i = 0; i < 7; i++) monday.add(Duration(days: i))];
  }

  bool hasEventsOn(DateTime day) {
    final d = AppDate.dateOnly(day);
    // Check shifts
    for (final s in financeStore.shifts) {
      final start = AppDate.dateOnly(DateTime.fromMillisecondsSinceEpoch(s.startAt));
      if (start == d) return true;
    }
    // Check forecast events
    final events = financeStore.forecast(horizonDays: 30).events;
    for (final e in events) {
      if (AppDate.dateOnly(e.date) == d) return true;
    }
    return false;
  }

  /// All agenda items sorted by date
  List<CalendarItem> get agendaItems {
    final items = <CalendarItem>[];
    final jobsById = {for (final j in financeStore.jobs) j.id: j};

    // 1. Shifts
    for (final s in financeStore.shifts) {
      final start = DateTime.fromMillisecondsSinceEpoch(s.startAt);
      final job = jobsById[s.jobId];
      final jobName = job?.name ?? 'Shift';
      final earnings = job != null ? ShiftEarnings.forShift(s, job) : null;
      final timeStr = s.endAt != null
          ? '${AppDate.timeOnly(start)}–${AppDate.timeOnly(DateTime.fromMillisecondsSinceEpoch(s.endAt!))}'
          : AppDate.timeOnly(start);

      final amount = earnings?.earningsMinor ?? (job != null ? job.hourlyRateMinor * 4 : 0);

      items.add(
        CalendarItem(
          id: 'shift_${s.id}',
          type: CalendarItemType.shift,
          title: '$jobName shift',
          subtitle: timeStr,
          date: start,
          amountMinor: amount,
          currencyCode: job?.currencyCode ?? baseCurrency,
          isIncome: true,
        ),
      );
    }

    // 2. Forecast events (bills, subscriptions, goal contributions)
    final forecast = financeStore.forecast(horizonDays: 30);
    for (var i = 0; i < forecast.events.length; i++) {
      final e = forecast.events[i];
      if (e.kind == ForecastEventKind.shift) continue; // already added from real shifts table

      final type = e.kind == ForecastEventKind.bill || e.kind == ForecastEventKind.subscription
          ? CalendarItemType.bill
          : CalendarItemType.goal;

      items.add(
        CalendarItem(
          id: 'forecast_$i',
          type: type,
          title: e.label,
          subtitle: type == CalendarItemType.bill ? 'Reminder on · Due ${AppDate.weekday(e.date)}' : 'Goal · weekly top-up',
          date: e.date,
          amountMinor: e.deltaMinor.abs(),
          currencyCode: baseCurrency,
          isIncome: e.isIncome,
        ),
      );
    }

    items.sort((a, b) => a.date.compareTo(b.date));
    return items;
  }

  @override
  void dispose() {
    financeStore.removeListener(_onStoreChanged);
    super.dispose();
  }
}
