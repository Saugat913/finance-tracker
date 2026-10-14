import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

abstract final class AddMenuSheet {
  static Future<void> show(BuildContext context) => showAddMenu(context);
}

/// "What would you like to add?" sheet, opened from Home and Calendar.
Future<void> showAddMenu(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (ctx) {
      void go(String route) {
        Navigator.of(ctx).pop();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.push(route);
          }
        });
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What would you like to add?', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: AppSpace.lg),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListRow(
                      title: 'Income or expense',
                      subtitle: 'Log money in or out',
                      leading: const IconTile(HugeIcons.strokeRoundedExchange01),
                      trailing: const Chevron(),
                      onTap: () => go(AppRoutes.addTransaction),
                    ),
                    const RowDivider(),
                    ListRow(
                      title: 'Shift',
                      subtitle: 'Schedule or log work',
                      leading: const IconTile(HugeIcons.strokeRoundedClock01),
                      trailing: const Chevron(),
                      onTap: () => go(AppRoutes.scheduleShift),
                    ),
                    const RowDivider(),
                    ListRow(
                      title: 'Job',
                      subtitle: 'Where you work and which days',
                      leading: const IconTile(HugeIcons.strokeRoundedBriefcase01),
                      trailing: const Chevron(),
                      onTap: () => go(AppRoutes.addJob),
                    ),
                    const RowDivider(),
                    ListRow(
                      title: 'Goal',
                      subtitle: 'Something to save for',
                      leading: const IconTile(HugeIcons.strokeRoundedTarget02),
                      trailing: const Chevron(),
                      onTap: () => go(AppRoutes.addGoal),
                    ),
                    const RowDivider(),
                    ListRow(
                      title: 'Account',
                      subtitle: 'Cash, bank or wallet',
                      leading: const IconTile(HugeIcons.strokeRoundedWallet01),
                      trailing: const Chevron(),
                      onTap: () => go(AppRoutes.addAccount),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
