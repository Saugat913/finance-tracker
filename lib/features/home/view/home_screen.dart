import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/home/view/widgets/home_transaction_row.dart';
import 'package:finance_tracker/features/home/view/widgets/upcoming_event_row.dart';
import 'package:finance_tracker/features/home/viewmodels/home_view_model.dart';
import 'package:finance_tracker/features/shell/view/add_menu_sheet.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<HomeViewModel>();

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final colors = context.colors;
        final text = Theme.of(context).textTheme;

        return TabPage(
          title: 'Overview',
          overline: AppDate.header(viewModel.now),
          actions: [
            RoundIconButton(
              HugeIcons.strokeRoundedNotification01,
              onPressed: () => context.push(AppRoutes.notifications),
            ),
            RoundIconButton(
              HugeIcons.strokeRoundedSlidersHorizontal,
              onPressed: () => context.push(AppRoutes.settings),
            ),
          ],
          children: [
            // Hero net position card
            if (!viewModel.hasAccounts)
              HeroCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Net position',
                      style: text.bodyMedium?.copyWith(color: colors.onHeroSecondary),
                    ),
                    const SizedBox(height: AppSpace.md),
                    Text(
                      MoneyFormatter.format(0, viewModel.baseCurrency),
                      style: text.displaySmall?.copyWith(color: colors.onHero, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      'Add an account and this fills in.',
                      style: text.bodySmall?.copyWith(color: colors.onHeroSecondary),
                    ),
                  ],
                ),
              )
            else
              HeroCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Net position',
                          style: text.bodyMedium?.copyWith(color: colors.onHeroSecondary),
                        ),
                        const Spacer(),
                        if (viewModel.monthIncome > 0 || viewModel.monthExpense > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.incomeBg,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              '+${MoneyFormatter.format(viewModel.netWorthMinor, viewModel.baseCurrency)} total',
                              style: text.labelSmall?.copyWith(
                                color: colors.income,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      MoneyFormatter.format(viewModel.netWorthMinor, viewModel.baseCurrency),
                      style: text.displaySmall?.copyWith(color: colors.onHero, fontWeight: FontWeight.w700),
                    ),
                    if (viewModel.sparklinePoints.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.md),
                      Sparkline(viewModel.sparklinePoints, color: colors.income, height: 48),
                    ],
                    const SizedBox(height: AppSpace.lg),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Income', style: text.bodySmall?.copyWith(color: colors.onHeroSecondary)),
                              Text(
                                MoneyFormatter.format(viewModel.monthIncome, viewModel.baseCurrency),
                                style: text.titleMedium?.copyWith(color: colors.onHero),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Spent', style: text.bodySmall?.copyWith(color: colors.onHeroSecondary)),
                              Text(
                                MoneyFormatter.format(viewModel.monthExpense, viewModel.baseCurrency),
                                style: text.titleMedium?.copyWith(color: colors.onHero),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Get set up checklist (if not completed)
            if (!viewModel.isSetupComplete) ...[
              const SizedBox(height: AppSpace.xl),
              Row(
                children: [
                  Expanded(child: Text('Get set up', style: text.titleMedium)),
                  Text(
                    '${viewModel.setupCompletedCount} of 4',
                    style: text.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _ChecklistRow(
                      step: '1',
                      title: 'Add an account',
                      subtitle: viewModel.hasAccounts
                          ? 'Done · ${viewModel.snapshot.accounts.first.name}'
                          : 'So your balance is real',
                      isDone: viewModel.hasAccounts,
                      onTap: () => context.push(AppRoutes.addAccount),
                    ),
                    const RowDivider(),
                    _ChecklistRow(
                      step: '2',
                      title: 'Add a job',
                      subtitle: viewModel.hasJobs
                          ? 'Done · ${viewModel.snapshot.jobs.first.name}'
                          : 'Your shifts will live here',
                      isDone: viewModel.hasJobs,
                      onTap: () => context.push(AppRoutes.addJob),
                    ),
                    const RowDivider(),
                    _ChecklistRow(
                      step: '3',
                      title: 'Set a goal',
                      subtitle: viewModel.hasGoals
                          ? 'Done · ${viewModel.snapshot.goals.first.name}'
                          : 'Give your money a reason',
                      isDone: viewModel.hasGoals,
                      onTap: () => context.push(AppRoutes.addGoal),
                    ),
                    const RowDivider(),
                    _ChecklistRow(
                      step: '4',
                      title: 'Turn on alerts',
                      subtitle: viewModel.hasAlerts
                          ? 'Done'
                          : 'Never miss a shift or a bill',
                      isDone: viewModel.hasAlerts,
                      onTap: () => context.push(AppRoutes.alerts),
                    ),
                  ],
                ),
              ),
            ],

            // Quick actions
            const SizedBox(height: AppSpace.xl),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    'Add',
                    icon: HugeIcons.strokeRoundedPlusSign,
                    onPressed: () => AddMenuSheet.show(context),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: AppButton(
                    'Start shift',
                    icon: HugeIcons.strokeRoundedPlay,
                    kind: AppButtonKind.outline,
                    onPressed: () => context.push(AppRoutes.startShift),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: AppButton(
                    'Ask AI',
                    icon: HugeIcons.strokeRoundedSparkles,
                    kind: AppButtonKind.outline,
                    onPressed: () => context.push(AppRoutes.assistant),
                  ),
                ),
              ],
            ),

            // This week section
            const SizedBox(height: AppSpace.xxl),
            SectionHeader(
              'This week',
              actionLabel: 'See calendar',
              onAction: () => context.go(AppRoutes.calendar),
            ),
            if (viewModel.upcomingEvents.isEmpty)
              AppCard(
                child: Text(
                  'Nothing coming up this week',
                  style: text.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < viewModel.upcomingEvents.take(4).length; i++) ...[
                      if (i > 0) const RowDivider(),
                      UpcomingEventRow(event: viewModel.upcomingEvents[i], currency: viewModel.baseCurrency),
                    ],
                  ],
                ),
              ),

            // Recent transactions section
            const SizedBox(height: AppSpace.xxl),
            SectionHeader(
              'Recent transactions',
              actionLabel: 'See all',
              onAction: () => context.push(AppRoutes.money),
            ),
            if (viewModel.recentTransactions.isEmpty)
              AppCard(
                child: Text(
                  'No transactions yet',
                  style: text.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < viewModel.recentTransactions.length; i++) ...[
                      if (i > 0) const RowDivider(),
                      HomeTransactionRow(
                        transaction: viewModel.recentTransactions[i],
                        currency: viewModel.baseCurrency,
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.onTap,
  });

  final String step;
  final String title;
  final String subtitle;
  final bool isDone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDone ? context.colors.incomeBg : context.colors.fill,
                shape: BoxShape.circle,
              ),
              child: isDone
                  ? Icon(Icons.check, size: 16, color: context.colors.income)
                  : Text(
                      step,
                      style: text.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleSmall),
                  Text(
                    subtitle,
                    style: text.bodySmall?.copyWith(
                      color: isDone ? context.colors.income : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isDone)
              const StatusChip('Done', tone: ChipTone.success)
            else
              const Chevron(),
          ],
        ),
      ),
    );
  }
}
