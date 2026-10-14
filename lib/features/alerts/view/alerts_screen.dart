import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/alerts/viewmodels/alerts_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<AlertsViewModel>();

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final text = Theme.of(context).textTheme;
        final settings = viewModel.settings;

        return Scaffold(
          appBar: const AppTopBar(),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.page, vertical: AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Which alerts do you want?', style: text.headlineMedium),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    'Change them any time.',
                    style: text.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),

                  Expanded(
                    child: ListView(
                      children: [
                        SwitchRow(
                          title: 'Shift reminders',
                          subtitle: '1 hour before',
                          value: settings.shiftReminders,
                          onChanged: viewModel.toggleShiftReminders,
                        ),
                        const SizedBox(height: AppSpace.sm),
                        SwitchRow(
                          title: 'Clock-out reminder',
                          subtitle: 'After 6 hours',
                          value: settings.clockOutReminder,
                          onChanged: viewModel.toggleClockOutReminder,
                        ),
                        const SizedBox(height: AppSpace.sm),
                        SwitchRow(
                          title: 'Bills due',
                          subtitle: '1 day before',
                          value: settings.billsDue,
                          onChanged: viewModel.toggleBillsDue,
                        ),
                        const SizedBox(height: AppSpace.sm),
                        SwitchRow(
                          title: 'Goal nudges',
                          subtitle: 'Weekly',
                          value: settings.goalNudges,
                          onChanged: viewModel.toggleGoalNudges,
                        ),
                        const SizedBox(height: AppSpace.sm),
                        SwitchRow(
                          title: 'Weekly summary',
                          subtitle: 'Sunday evening',
                          value: settings.weeklySummary,
                          onChanged: viewModel.toggleWeeklySummary,
                        ),
                        const SizedBox(height: AppSpace.sm),
                        SwitchRow(
                          title: 'Quiet hours',
                          subtitle: '10 pm to 7 am',
                          value: settings.quietHours,
                          onChanged: viewModel.toggleQuietHours,
                        ),
                      ],
                    ),
                  ),

                  AppButton(
                    'Done',
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
