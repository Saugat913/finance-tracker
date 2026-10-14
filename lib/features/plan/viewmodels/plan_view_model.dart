import 'package:flutter/foundation.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/telemetry/telemetry_service.dart';
import 'package:finance_tracker/features/plan/data/forecast_engine.dart';
import 'package:finance_tracker/features/plan/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';

class PlanViewModel extends ChangeNotifier {
  PlanViewModel({
    required this.financeStore,
    required this.goalRepo,
  }) {
    financeStore.addListener(_onStoreChanged);
  }

  final FinanceStore financeStore;
  final GoalRepository goalRepo;

  void _onStoreChanged() {
    notifyListeners();
  }

  String get baseCurrency => financeStore.baseCurrency;
  List<Goal> get goals => financeStore.goals;

  ForecastResult get forecast => financeStore.forecast(horizonDays: 90);

  int get projectedBalanceIn3Months => forecast.endMinor;

  List<GoalForecast> get goalForecasts => forecast.goalForecasts;

  Future<int> addGoal({
    required String name,
    required int targetAmountMinor,
    DateTime? targetDate,
    int? initialSavedMinor,
    String? category,
  }) async {
    final goalId = await goalRepo.add(
      name: name,
      targetAmountMinor: targetAmountMinor,
      currencyCode: baseCurrency,
      targetDate: targetDate,
      note: category,
    );

    if (initialSavedMinor != null && initialSavedMinor > 0) {
      await goalRepo.addContribution(
        goalId: goalId,
        amountMinor: initialSavedMinor,
        note: 'Initial deposit',
      );
    }

    TelemetryService.instance.trackEvent('goal_created', {
      'name': name,
      'targetAmount': targetAmountMinor,
    });

    return goalId;
  }

  @override
  void dispose() {
    financeStore.removeListener(_onStoreChanged);
    super.dispose();
  }
}
