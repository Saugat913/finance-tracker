import 'package:flutter/foundation.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/shared/data/finance_snapshot.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/plan/data/forecast_engine.dart';
import 'package:finance_tracker/core/database/app_database.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required this.financeStore,
    required this.settingsRepo,
  }) {
    financeStore.addListener(_onStoreChanged);
    settingsRepo.addListener(_onStoreChanged);
  }

  final FinanceStore financeStore;
  final SettingsRepository settingsRepo;

  void _onStoreChanged() {
    notifyListeners();
  }

  FinanceSnapshot get snapshot => financeStore.snapshot;
  String get baseCurrency => financeStore.baseCurrency;
  DateTime get now => snapshot.now;

  int get netWorthMinor => snapshot.netWorthMinor;

  bool get hasAccounts => snapshot.accounts.isNotEmpty;
  bool get hasJobs => snapshot.jobs.isNotEmpty;
  bool get hasGoals => snapshot.goals.isNotEmpty;
  bool get hasAlerts =>
      settingsRepo.settings.shiftReminders || settingsRepo.settings.billsDue;

  int get setupCompletedCount {
    var count = 0;
    if (hasAccounts) count++;
    if (hasJobs) count++;
    if (hasGoals) count++;
    if (hasAlerts) count++;
    return count;
  }

  bool get isSetupComplete => setupCompletedCount == 4;

  ForecastResult get forecast => financeStore.forecast(horizonDays: 30);

  List<ForecastEvent> get upcomingEvents => forecast.upcomingWithin(7, now);

  List<Transaction> get recentTransactions =>
      snapshot.transactions.take(5).toList();

  int get monthIncome {
    final start = DateTime(now.year, now.month);
    return snapshot.incomeInMonth(start);
  }

  int get monthExpense {
    final start = DateTime(now.year, now.month);
    return snapshot.expenseInMonth(start);
  }

  List<double> get sparklinePoints {
    if (forecast.points.isEmpty) return const [];
    final pts = forecast.points.map((p) => p.balanceMinor.toDouble()).toList();
    if (pts.length <= 8) return pts;
    final step = pts.length / 8;
    return [for (var i = 0; i < 8; i++) pts[(i * step).floor()]];
  }

  @override
  void dispose() {
    financeStore.removeListener(_onStoreChanged);
    settingsRepo.removeListener(_onStoreChanged);
    super.dispose();
  }
}
