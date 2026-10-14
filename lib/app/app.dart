import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/router/app_router.dart';
import 'package:finance_tracker/core/theme/app_theme.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';

class FinanceTrackerApp extends StatelessWidget {
  const FinanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsRepo = getIt<SettingsRepository>();

    return ListenableBuilder(
      listenable: settingsRepo,
      builder: (context, _) {
        return MaterialApp.router(
          title: 'Tilvane',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settingsRepo.settings.themeMode,
          locale: settingsRepo.locale,
          supportedLocales: const [Locale('en'), Locale('ne'), Locale('hi')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: appRouter,
        );
      },
    );
  }
}
