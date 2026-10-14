import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/analytics/data/insights_engine.dart';
import 'package:finance_tracker/features/analytics/viewmodels/analytics_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<AnalyticsViewModel>();

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final text = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;
        final colors = context.colors;
        final report = viewModel.report;

        return TabPage(
          title: 'Analytics',
          overline: 'Insights',
          children: [
            // Period tabs
            SegmentedTabs<InsightsPeriod>(
              options: const {
                InsightsPeriod.week: 'Week',
                InsightsPeriod.month: 'Month',
                InsightsPeriod.quarter: 'Year',
              },
              value: viewModel.period,
              onChanged: viewModel.setPeriod,
            ),
            const SizedBox(height: AppSpace.xl),

            if (!viewModel.hasData)
              EmptyState(
                icon: HugeIcons.strokeRoundedChartHistogram,
                title: 'No data to chart yet',
                message: 'Add a few transactions and your spending will show up here.',
                actionLabel: 'Add transaction',
                onAction: () => context.push(AppRoutes.addTransaction),
              )
            else ...[
              // Spent summary card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spent in ${report.period.label.toLowerCase()} so far',
                      style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      MoneyFormatter.format(report.expenseMinor, viewModel.baseCurrency),
                      style: text.displaySmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      report.previousExpenseMinor > 0
                          ? 'Spending is ${(report.expenseChange.abs() * 100).toStringAsFixed(0)}% '
                              '${report.expenseChange <= 0 ? "lower" : "higher"} than previous'
                          : 'Recorded activity for this period',
                      style: text.bodySmall?.copyWith(
                        color: report.expenseChange <= 0 ? colors.income : colors.expense,
                      ),
                    ),
                    if (report.dailyExpense.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.xl),
                      _SpendingBarChart(
                        values: report.dailyExpense,
                        labels: report.dailyLabels,
                        color: scheme.onSurface,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.lg),

              // Income and Net mini card
              AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Income', style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                          const SizedBox(height: 2),
                          Text(
                            MoneyFormatter.format(report.incomeMinor, viewModel.baseCurrency),
                            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Net', style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                          const SizedBox(height: 2),
                          MoneyText(
                            report.netMinor,
                            viewModel.baseCurrency,
                            signed: true,
                            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Where it went section
              if (report.categoryBreakdown.isNotEmpty) ...[
                const SizedBox(height: AppSpace.xxl),
                const SectionHeader('Where it went'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < report.categoryBreakdown.length; i++) ...[
                        if (i > 0) const RowDivider(),
                        _CategorySpendRow(
                          spend: report.categoryBreakdown[i],
                          totalMinor: report.expenseMinor,
                          currency: viewModel.baseCurrency,
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Top merchants section
              if (_extractTopMerchants(viewModel.financeStore.transactions).isNotEmpty) ...[
                const SizedBox(height: AppSpace.xxl),
                const SectionHeader('Top merchants'),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0;
                          i < _extractTopMerchants(viewModel.financeStore.transactions).take(4).length;
                          i++) ...[
                        if (i > 0) const RowDivider(),
                        _MerchantRow(
                          merchant: _extractTopMerchants(viewModel.financeStore.transactions)[i],
                          currency: viewModel.baseCurrency,
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Projected month-end card
              const SizedBox(height: AppSpace.xl),
              AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Projected month-end: ${MoneyFormatter.format(viewModel.projectedMonthEndMinor, viewModel.baseCurrency)}',
                            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text('Based on your usual spending', style: text.bodySmall),
                        ],
                      ),
                    ),
                    const StatusChip('On track', tone: ChipTone.success),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  List<_MerchantSpend> _extractTopMerchants(List<dynamic> txs) {
    final map = <String, (int, int, String)>{};
    for (final t in txs) {
      // Merchant is stored as the first part of the note: "Woolworths · weekly shop".
      if (t.type != 'expense') continue;
      final note = (t.note as String?)?.trim() ?? '';
      if (note.isEmpty) continue;
      final name = note.split(' · ').first;
      final existing = map[name];
      if (existing == null) {
        map[name] = (t.amountMinor as int, 1, t.category as String);
      } else {
        map[name] = (existing.$1 + (t.amountMinor as int), existing.$2 + 1, existing.$3);
      }
    }
    final list = map.entries
        .map((e) => _MerchantSpend(name: e.key, amountMinor: e.value.$1, count: e.value.$2, category: e.value.$3))
        .toList();
    list.sort((a, b) => b.amountMinor.compareTo(a.amountMinor));
    return list;
  }
}

class _MerchantSpend {
  _MerchantSpend({required this.name, required this.amountMinor, required this.count, required this.category});
  final String name;
  final int amountMinor;
  final int count;
  final String category;
}

class _SpendingBarChart extends StatelessWidget {
  const _SpendingBarChart({required this.values, required this.labels, required this.color});

  final List<double> values;
  final List<String> labels;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final max = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    final effectiveMax = max <= 0 ? 1.0 : max;

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: (values[i] / effectiveMax * 80).clamp(6.0, 80.0),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      i < labels.length ? labels[i] : '',
                      style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategorySpendRow extends StatelessWidget {
  const _CategorySpendRow({required this.spend, required this.totalMinor, required this.currency});

  final CategorySpend spend;
  final int totalMinor;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final percent = totalMinor > 0 ? (spend.amountMinor / totalMinor * 100).round() : 0;

    return Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(spend.label, style: text.titleSmall),
              ),
              Text('$percent%', style: text.bodySmall),
              const SizedBox(width: AppSpace.md),
              MoneyText(spend.amountMinor, currency, style: text.titleSmall),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          ProgressLine(totalMinor > 0 ? spend.amountMinor / totalMinor : 0),
        ],
      ),
    );
  }
}

class _MerchantRow extends StatelessWidget {
  const _MerchantRow({required this.merchant, required this.currency});

  final _MerchantSpend merchant;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Row(
        children: [
          LetterAvatar(merchant.name),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(merchant.name, style: text.titleSmall),
                Text('${merchant.category} · ${merchant.count} visits', style: text.bodySmall),
              ],
            ),
          ),
          MoneyText(merchant.amountMinor, currency, style: text.titleSmall),
        ],
      ),
    );
  }
}
