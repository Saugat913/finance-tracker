import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/features/money/view/widgets/transaction_item_row.dart';
import 'package:finance_tracker/features/money/viewmodels/money_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class MoneyScreen extends StatelessWidget {
  const MoneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<MoneyViewModel>();

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final text = Theme.of(context).textTheme;
        final txs = viewModel.transactions;

        return Scaffold(
          appBar: AppTopBar(
            title: 'Money',
            actions: [
              TopBarAction(HugeIcons.strokeRoundedPlusSign, onPressed: () => context.push(AppRoutes.addTransaction)),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.page, vertical: AppSpace.md),
              children: [
                SegmentedTabs<MoneyFilterTab>(
                  options: const {
                    MoneyFilterTab.all: 'All',
                    MoneyFilterTab.income: 'Income',
                    MoneyFilterTab.expenses: 'Expenses',
                  },
                  value: viewModel.tab,
                  onChanged: viewModel.setTab,
                ),
                const SizedBox(height: AppSpace.xl),

                if (txs.isEmpty)
                  SizedBox(
                    height: 400,
                    child: EmptyState(
                      icon: HugeIcons.strokeRoundedCoins01,
                      title: 'No transactions yet',
                      message: 'Add your first income or expense and it will show up here.',
                      actionLabel: 'Add transaction',
                      onAction: () => context.push(AppRoutes.addTransaction),
                    ),
                  )
                else ...[
                  for (final group in _groupTransactions(txs)) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                      child: Text(
                        AppDate.weekdayDay(group.date),
                        style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var i = 0; i < group.transactions.length; i++) ...[
                            if (i > 0) const RowDivider(),
                            TransactionItemRow(
                              transaction: group.transactions[i],
                              currency: viewModel.baseCurrency,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<_DayGroup> _groupTransactions(List<Transaction> list) {
    final groups = <DateTime, List<Transaction>>{};
    for (final t in list) {
      final date = AppDate.dateOnly(DateTime.fromMillisecondsSinceEpoch(t.occurredAt));
      groups.putIfAbsent(date, () => []).add(t);
    }
    return groups.entries.map((e) => _DayGroup(date: e.key, transactions: e.value)).toList();
  }
}

class _DayGroup {
  _DayGroup({required this.date, required this.transactions});
  final DateTime date;
  final List<Transaction> transactions;
}
