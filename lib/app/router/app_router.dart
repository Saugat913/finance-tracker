import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/features/accounts/view/accounts_screen.dart';
import 'package:finance_tracker/features/accounts/view/wizards/add_account_wizard.dart';
import 'package:finance_tracker/features/accounts/view/wizards/edit_account_screen.dart';
import 'package:finance_tracker/features/alerts/view/alerts_screen.dart';
import 'package:finance_tracker/features/alerts/view/notifications_screen.dart';
import 'package:finance_tracker/features/analytics/view/analytics_screen.dart';
import 'package:finance_tracker/features/assistant/view/assistant_screen.dart';
import 'package:finance_tracker/features/calendar/view/calendar_screen.dart';
import 'package:finance_tracker/features/home/view/home_screen.dart';
import 'package:finance_tracker/features/money/view/money_screen.dart';
import 'package:finance_tracker/features/money/view/wizards/add_transaction_wizard.dart';
import 'package:finance_tracker/features/onboarding/view/currency_first_run_screen.dart';
import 'package:finance_tracker/features/onboarding/view/welcome_screen.dart';
import 'package:finance_tracker/features/plan/view/plan_screen.dart';
import 'package:finance_tracker/features/plan/view/wizards/add_goal_wizard.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/settings/view/backup_screen.dart';
import 'package:finance_tracker/features/settings/view/currency_settings_screen.dart';
import 'package:finance_tracker/features/settings/view/settings_screen.dart';
import 'package:finance_tracker/features/shell/view/app_shell.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';
import 'package:finance_tracker/features/work/view/wizards/add_job_wizard.dart';
import 'package:finance_tracker/features/work/view/wizards/live_shift_screen.dart';
import 'package:finance_tracker/features/work/view/wizards/schedule_shift_wizard.dart';
import 'package:finance_tracker/features/work/view/wizards/shift_done_screen.dart';
import 'package:finance_tracker/features/work/view/wizards/start_shift_sheet.dart';
import 'package:finance_tracker/features/work/view/work_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorHome = GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final GlobalKey<NavigatorState> _shellNavigatorCalendar = GlobalKey<NavigatorState>(debugLabel: 'shellCalendar');
final GlobalKey<NavigatorState> _shellNavigatorAnalytics = GlobalKey<NavigatorState>(debugLabel: 'shellAnalytics');
final GlobalKey<NavigatorState> _shellNavigatorWork = GlobalKey<NavigatorState>(debugLabel: 'shellWork');
final GlobalKey<NavigatorState> _shellNavigatorPlan = GlobalKey<NavigatorState>(debugLabel: 'shellPlan');

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  refreshListenable: getIt<SettingsRepository>(),
  initialLocation: AppRoutes.home,
  redirect: (context, state) {
    final settingsRepo = getIt<SettingsRepository>();
    final location = state.matchedLocation;

    if (!settingsRepo.settings.onboarded) {
      final onboarding = location == AppRoutes.welcome || location == AppRoutes.currency;
      return onboarding ? null : AppRoutes.welcome;
    }

    if (location == AppRoutes.welcome || location == AppRoutes.currency) {
      return AppRoutes.home;
    }

    return null;
  },
  routes: [
    // Entry / Onboarding
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.welcome,
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.currency,
      builder: (context, state) => const CurrencyFirstRunScreen(),
    ),

    // Bottom Navigation Shell (5 tabs)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AppShell(shell: navigationShell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellNavigatorHome,
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorCalendar,
          routes: [
            GoRoute(
              path: AppRoutes.calendar,
              builder: (context, state) => const CalendarScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorAnalytics,
          routes: [
            GoRoute(
              path: AppRoutes.analytics,
              builder: (context, state) => const AnalyticsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorWork,
          routes: [
            GoRoute(
              path: AppRoutes.work,
              builder: (context, state) => const WorkScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorPlan,
          routes: [
            GoRoute(
              path: AppRoutes.plan,
              builder: (context, state) => const PlanScreen(),
            ),
          ],
        ),
      ],
    ),

    // Money routes
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.money,
      builder: (context, state) => const MoneyScreen(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.addTransaction,
      builder: (context, state) => const AddTransactionWizard(),
    ),

    // Accounts routes
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.accounts,
      builder: (context, state) => const AccountsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.addAccount,
      builder: (context, state) => const AddAccountWizard(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.accountPattern,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 1;
        return EditAccountScreen(accountId: id);
      },
    ),

    // Work routes
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.addJob,
      builder: (context, state) => const AddJobWizard(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.scheduleShift,
      builder: (context, state) => const ScheduleShiftWizard(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.startShift,
      builder: (context, state) => const StartShiftSheet(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.liveShift,
      builder: (context, state) => const LiveShiftScreen(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.shiftDonePattern,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 1;
        final earnings = state.extra is ShiftEarnings ? state.extra as ShiftEarnings : null;
        return ShiftDoneScreen(shiftId: id, earnings: earnings);
      },
    ),

    // Plan routes
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.addGoal,
      builder: (context, state) => const AddGoalWizard(),
    ),

    // Alerts & Notifications
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.notifications,
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.alerts,
      builder: (context, state) => const AlertsScreen(),
    ),

    // Assistant
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.assistant,
      builder: (context, state) => const AssistantScreen(),
    ),

    // Settings
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.currencySettings,
      builder: (context, state) => const CurrencySettingsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      path: AppRoutes.backup,
      builder: (context, state) => const BackupScreen(),
    ),
  ],
);
