import 'package:get_it/get_it.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/accounts/data/model/account_type.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/accounts/viewmodels/accounts_view_model.dart';
import 'package:finance_tracker/features/alerts/viewmodels/alerts_view_model.dart';
import 'package:finance_tracker/features/analytics/viewmodels/analytics_view_model.dart';
import 'package:finance_tracker/features/assistant/viewmodels/assistant_view_model.dart';
import 'package:finance_tracker/features/calendar/viewmodels/calendar_view_model.dart';
import 'package:finance_tracker/features/home/viewmodels/home_view_model.dart';
import 'package:finance_tracker/features/money/data/repository/recurring_repository.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/money/viewmodels/money_view_model.dart';
import 'package:finance_tracker/features/plan/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/plan/viewmodels/plan_view_model.dart';
import 'package:finance_tracker/features/settings/data/repository/data_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/exchange_rate_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/settings/viewmodels/settings_view_model.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/work/data/repository/job_repository.dart';
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  if (getIt.isRegistered<AppDatabase>()) return;

  // 1. Database
  final db = AppDatabase();
  getIt.registerSingleton<AppDatabase>(db);

  // 2. Concrete Repositories
  final accountRepo = AccountRepository(db);
  final transactionRepo = TransactionRepository(db);
  final recurringRepo = RecurringRepository(db);
  final jobRepo = JobRepository(db);
  final shiftRepo = ShiftRepository(db);
  final goalRepo = GoalRepository(db);
  final ratesRepo = ExchangeRateRepository(db);
  final settingsRepo = SettingsRepository(db);
  final dataRepo = DataRepository(db);

  await settingsRepo.load();

  getIt
    ..registerSingleton<AccountRepository>(accountRepo)
    ..registerSingleton<TransactionRepository>(transactionRepo)
    ..registerSingleton<RecurringRepository>(recurringRepo)
    ..registerSingleton<JobRepository>(jobRepo)
    ..registerSingleton<ShiftRepository>(shiftRepo)
    ..registerSingleton<GoalRepository>(goalRepo)
    ..registerSingleton<ExchangeRateRepository>(ratesRepo)
    ..registerSingleton<SettingsRepository>(settingsRepo)
    ..registerSingleton<DataRepository>(dataRepo);

  // 3. Central FinanceStore
  final financeStore = FinanceStore(
    accountsRepo: accountRepo,
    transactionsRepo: transactionRepo,
    recurringRepo: recurringRepo,
    jobsRepo: jobRepo,
    shiftsRepo: shiftRepo,
    goalsRepo: goalRepo,
    ratesRepo: ratesRepo,
    settingsRepo: settingsRepo,
  );
  financeStore.start();
  getIt.registerSingleton<FinanceStore>(financeStore);

  final existingAccounts = await accountRepo.watchAll().first;
  if (existingAccounts.isEmpty) {
    await accountRepo.add(
      name: 'Everyday',
      type: AccountType.bank,
      openingBalanceMinor: 0,
      currencyCode: settingsRepo.settings.baseCurrency,
    );
  }

  // 4. ViewModels
  getIt
    ..registerLazySingleton<HomeViewModel>(
      () => HomeViewModel(
        financeStore: getIt<FinanceStore>(),
        settingsRepo: getIt<SettingsRepository>(),
      ),
    )
    ..registerLazySingleton<CalendarViewModel>(
      () => CalendarViewModel(financeStore: getIt<FinanceStore>()),
    )
    ..registerLazySingleton<AnalyticsViewModel>(
      () => AnalyticsViewModel(financeStore: getIt<FinanceStore>()),
    )
    ..registerLazySingleton<WorkViewModel>(
      () => WorkViewModel(
        financeStore: getIt<FinanceStore>(),
        jobRepo: getIt<JobRepository>(),
        shiftRepo: getIt<ShiftRepository>(),
      ),
    )
    ..registerLazySingleton<PlanViewModel>(
      () => PlanViewModel(
        financeStore: getIt<FinanceStore>(),
        goalRepo: getIt<GoalRepository>(),
      ),
    )
    ..registerLazySingleton<MoneyViewModel>(
      () => MoneyViewModel(
        financeStore: getIt<FinanceStore>(),
        transactionRepo: getIt<TransactionRepository>(),
      ),
    )
    ..registerLazySingleton<AccountsViewModel>(
      () => AccountsViewModel(
        financeStore: getIt<FinanceStore>(),
        accountRepo: getIt<AccountRepository>(),
      ),
    )
    ..registerLazySingleton<AlertsViewModel>(
      () => AlertsViewModel(
        financeStore: getIt<FinanceStore>(),
        settingsRepo: getIt<SettingsRepository>(),
      ),
    )
    ..registerLazySingleton<AssistantViewModel>(
      () => AssistantViewModel(
        financeStore: getIt<FinanceStore>(),
        transactionRepo: getIt<TransactionRepository>(),
        shiftRepo: getIt<ShiftRepository>(),
        goalRepo: getIt<GoalRepository>(),
      ),
    )
    ..registerLazySingleton<SettingsViewModel>(
      () => SettingsViewModel(
        settingsRepo: getIt<SettingsRepository>(),
        dataRepo: getIt<DataRepository>(),
        financeStore: getIt<FinanceStore>(),
      ),
    );
}
