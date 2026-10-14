import 'package:flutter/foundation.dart';
import 'package:finance_tracker/features/analytics/data/insights_engine.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';

class AnalyticsViewModel extends ChangeNotifier {
  AnalyticsViewModel({required this.financeStore}) {
    financeStore.addListener(_onStoreChanged);
  }

  final FinanceStore financeStore;

  InsightsPeriod _period = InsightsPeriod.month;
  InsightsPeriod get period => _period;
  String get baseCurrency => financeStore.baseCurrency;

  void _onStoreChanged() {
    notifyListeners();
  }

  void setPeriod(InsightsPeriod period) {
    _period = period;
    notifyListeners();
  }

  InsightsReport get report => financeStore.insights(_period);

  bool get hasData => report.hasSpending || report.incomeMinor > 0;

  int get projectedMonthEndMinor {
    final forecast = financeStore.forecast(horizonDays: 30);
    return forecast.endMinor;
  }

  @override
  void dispose() {
    financeStore.removeListener(_onStoreChanged);
    super.dispose();
  }
}
