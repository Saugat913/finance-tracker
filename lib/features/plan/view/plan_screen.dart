import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/plan/viewmodels/plan_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<PlanViewModel>();

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final text = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;
        final colors = context.colors;
        final forecasts = viewModel.goalForecasts;

        return TabPage(
          title: 'Plan',
          overline: 'Forecast and goals',
          floating: GestureDetector(
            onTap: () => context.push(AppRoutes.assistant),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
              decoration: BoxDecoration(
                color: colors.hero,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(HugeIcons.strokeRoundedSparkles, size: 18, color: colors.onHero),
                  const SizedBox(width: AppSpace.sm),
                  Text(
                    'Assistant',
                    style: text.labelMedium?.copyWith(
                      color: colors.onHero,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          children: [
            // Projected balance in 3 months
            HeroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Projected balance in 3 months',
                    style: text.bodyMedium?.copyWith(color: colors.onHeroSecondary),
                  ),
                  const SizedBox(height: AppSpace.md),
                  Text(
                    MoneyFormatter.format(viewModel.projectedBalanceIn3Months, viewModel.baseCurrency),
                    style: text.displaySmall?.copyWith(
                      color: colors.onHero,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.xxl),

            // Goals section header
            Row(
              children: [
                Expanded(child: Text('Goals', style: text.titleMedium)),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.addGoal),
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    '+ New goal',
                    style: text.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),

            if (viewModel.goals.isEmpty)
              EmptyState(
                icon: HugeIcons.strokeRoundedTarget02,
                title: 'No goals yet',
                message: 'Set a goal and we will work out how much to save each month.',
                actionLabel: 'Set a goal',
                onAction: () => context.push(AppRoutes.addGoal),
              )
            else ...[
              for (final gf in forecasts) ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              gf.goal.name,
                              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.fill,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              '${(gf.progress.fraction * 100).round()}%',
                              style: text.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${MoneyFormatter.format(gf.progress.savedMinor, gf.goal.currencyCode)} '
                        'of ${MoneyFormatter.format(gf.goal.targetAmountMinor, gf.goal.currencyCode)}',
                        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpace.md),
                      ProgressLine(gf.progress.fraction),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.md),
              ],
            ],
          ],
        );
      },
    );
  }
}
