import 'package:flutter/material.dart';
import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/accounts/data/account_repository.dart';
import 'package:finance_tracker/features/transactions/data/transaction_repository.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_categories.dart';
import 'package:finance_tracker/features/transactions/domain/transaction_type.dart';
import 'package:finance_tracker/features/transfers/data/transfer_repository.dart';

/// Calendar view of recorded income, expenses, and account transfers.
///
/// Scheduled bills and other future financial events will need their own
/// persistence model; this screen intentionally only shows saved activity.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _visibleMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  void _changeMonth(int offset) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + offset);
      final lastDay = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + 1,
        0,
      ).day;
      _selectedDate = DateTime(
        _visibleMonth.year,
        _visibleMonth.month,
        _selectedDate.day.clamp(1, lastDay),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: StreamBuilder<List<Account>>(
        stream: getIt<AccountRepository>().watchAccounts(),
        builder: (context, accountSnapshot) {
          if (accountSnapshot.hasError) {
            return const _CalendarMessage('Could not load accounts.');
          }
          if (!accountSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<List<Transaction>>(
            stream: getIt<TransactionRepository>().watchTransactions(),
            builder: (context, transactionSnapshot) {
              if (transactionSnapshot.hasError) {
                return const _CalendarMessage('Could not load transactions.');
              }
              if (!transactionSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return StreamBuilder<List<Transfer>>(
                stream: getIt<TransferRepository>().watchTransfers(),
                builder: (context, transferSnapshot) {
                  if (transferSnapshot.hasError) {
                    return const _CalendarMessage('Could not load transfers.');
                  }
                  if (!transferSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return _buildContent(
                    context,
                    theme,
                    accountSnapshot.data!,
                    transactionSnapshot.data!,
                    transferSnapshot.data!,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    List<Account> accounts,
    List<Transaction> transactions,
    List<Transfer> transfers,
  ) {
    final accountById = {for (final account in accounts) account.id: account};
    final selectedTransactions = transactions.where((transaction) {
      return DateUtils.isSameDay(
        DateTime.fromMillisecondsSinceEpoch(transaction.occurredAt),
        _selectedDate,
      );
    }).toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    final selectedTransfers = transfers.where((transfer) {
      return DateUtils.isSameDay(
        DateTime.fromMillisecondsSinceEpoch(transfer.occurredAt),
        _selectedDate,
      );
    }).toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    final activityDates = <DateTime>{
      for (final transaction in transactions)
        DateUtils.dateOnly(
          DateTime.fromMillisecondsSinceEpoch(transaction.occurredAt),
        ),
      for (final transfer in transfers)
        DateUtils.dateOnly(
          DateTime.fromMillisecondsSinceEpoch(transfer.occurredAt),
        ),
    };

    final monthTransactions = transactions.where((transaction) {
      final date = DateTime.fromMillisecondsSinceEpoch(transaction.occurredAt);
      return date.year == _visibleMonth.year && date.month == _visibleMonth.month;
    });
    final incomeMinor = monthTransactions
        .where((transaction) => transaction.type == TransactionType.income.value)
        .fold<int>(0, (sum, transaction) => sum + transaction.amountMinor);
    final expenseMinor = monthTransactions
        .where((transaction) => transaction.type == TransactionType.expense.value)
        .fold<int>(0, (sum, transaction) => sum + transaction.amountMinor);

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth > AppDimensions.pageMaxWidth
            ? (constraints.maxWidth - AppDimensions.pageMaxWidth) / 2
            : AppDimensions.screenPadding;

        return ListView(
          padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 32),
          children: [
            Text('Calendar', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Your financial activity by date',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _MonthSummary(
              incomeMinor: incomeMinor,
              expenseMinor: expenseMinor,
              currencyCodes: {
                for (final transaction in monthTransactions)
                  accountById[transaction.accountId]?.currencyCode ?? 'NPR',
              }.toList()
                ..sort(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _changeMonth(-1),
                        tooltip: 'Previous month',
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Expanded(
                        child: Text(
                          _monthLabel(_visibleMonth),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _changeMonth(1),
                        tooltip: 'Next month',
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      _WeekdayLabel('M'),
                      _WeekdayLabel('T'),
                      _WeekdayLabel('W'),
                      _WeekdayLabel('T'),
                      _WeekdayLabel('F'),
                      _WeekdayLabel('S'),
                      _WeekdayLabel('S'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _MonthGrid(
                    month: _visibleMonth,
                    selectedDate: _selectedDate,
                    activityDates: activityDates,
                    onSelect: (date) => setState(() => _selectedDate = date),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LegendDot(color: theme.colorScheme.tertiary),
                      const SizedBox(width: 5),
                      Text('Income', style: theme.textTheme.labelSmall),
                      const SizedBox(width: 16),
                      _LegendDot(color: theme.colorScheme.error),
                      const SizedBox(width: 5),
                      Text('Expense', style: theme.textTheme.labelSmall),
                      const SizedBox(width: 16),
                      _LegendDot(color: theme.colorScheme.primary),
                      const SizedBox(width: 5),
                      Text('Activity', style: theme.textTheme.labelSmall),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDateLabel(_selectedDate),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                Text(
                  '${selectedTransactions.length + selectedTransfers.length} items',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (selectedTransactions.isEmpty && selectedTransfers.isEmpty)
              _NoActivityCard(date: _selectedDate)
            else ...[
              for (final transaction in selectedTransactions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TransactionTile(
                    transaction: transaction,
                    account: accountById[transaction.accountId],
                  ),
                ),
              for (final transfer in selectedTransfers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TransferTile(
                    transfer: transfer,
                    source: accountById[transfer.sourceAccountId],
                    destination: accountById[transfer.destinationAccountId],
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selectedDate,
    required this.activityDates,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selectedDate;
  final Set<DateTime> activityDates;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstWeekdayOffset = DateTime(month.year, month.month, 1).weekday - 1;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 42,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemBuilder: (context, index) {
        final day = index - firstWeekdayOffset + 1;
        if (day < 1 || day > daysInMonth) return const SizedBox.shrink();

        final date = DateTime(month.year, month.month, day);
        final selected = DateUtils.isSameDay(date, selectedDate);
        final today = DateUtils.isSameDay(date, DateTime.now());
        final hasActivity = activityDates.contains(date);
        final foreground = selected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface;

        return Material(
          color: selected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onSelect(date),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: today && !selected
                      ? BoxDecoration(
                          border: Border.all(color: theme.colorScheme.primary),
                          shape: BoxShape.circle,
                        )
                      : null,
                  child: Text(
                    '$day',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foreground,
                      fontWeight: selected || today ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: hasActivity
                        ? (selected ? foreground : theme.colorScheme.primary)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MonthSummary extends StatelessWidget {
  const _MonthSummary({
    required this.incomeMinor,
    required this.expenseMinor,
    required this.currencyCodes,
  });

  final int incomeMinor;
  final int expenseMinor;
  final List<String> currencyCodes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final singleCurrency = currencyCodes.length == 1;
    final hasMixedCurrencies = currencyCodes.length > 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryValue(
              label: 'Income this month',
              value: singleCurrency
                  ? _formatMoney(incomeMinor, currencyCodes.first)
                  : hasMixedCurrencies
                      ? 'Multiple'
                      : '—',
              color: theme.colorScheme.tertiary,
            ),
          ),
          Container(
            width: 1,
            height: 42,
            color: theme.colorScheme.outlineVariant,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _SummaryValue(
              label: 'Expenses this month',
              value: singleCurrency
                  ? _formatMoney(expenseMinor, currencyCodes.first)
                  : hasMixedCurrencies
                      ? 'Multiple'
                      : '—',
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction, required this.account});

  final Transaction transaction;
  final Account? account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = TransactionType.fromValue(transaction.type);
    final category = TransactionCategories.fromValue(transaction.category, type);
    final isIncome = type == TransactionType.income;
    final color = isIncome ? theme.colorScheme.tertiary : theme.colorScheme.error;

    return _ActivityCard(
      icon: isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
      color: color,
      title: category.label,
      subtitle: [
        if (account != null) account!.name,
        if (transaction.note?.isNotEmpty == true) transaction.note!,
      ].join(' · '),
      amount: '${isIncome ? '+' : '−'}${_formatMoney(transaction.amountMinor, account?.currencyCode ?? 'NPR')}',
    );
  }
}

class _TransferTile extends StatelessWidget {
  const _TransferTile({
    required this.transfer,
    required this.source,
    required this.destination,
  });

  final Transfer transfer;
  final Account? source;
  final Account? destination;

  @override
  Widget build(BuildContext context) {
    return _ActivityCard(
      icon: Icons.swap_horiz_rounded,
      color: Theme.of(context).colorScheme.primary,
      title: '${source?.name ?? 'Account'} → ${destination?.name ?? 'Account'}',
      subtitle: transfer.note ?? 'Account transfer',
      amount: _formatMoney(transfer.amountMinor, source?.currencyCode ?? 'NPR'),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              amount,
              textAlign: TextAlign.end,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoActivityCard extends StatelessWidget {
  const _NoActivityCard({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.event_available_rounded,
              size: 34, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 10),
          Text('No activity on this day', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Recorded income, expenses, and transfers will appear here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _CalendarMessage extends StatelessWidget {
  const _CalendarMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Center(child: Text(message));
}

String _monthLabel(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

String _selectedDateLabel(DateTime date) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
}

String _formatMoney(int minor, String currencyCode) {
  final amount = minor / 100;
  final parts = amount.toStringAsFixed(2).split('.');
  final whole = parts[0];
  final grouped = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return '$currencyCode $grouped.${parts[1]}';
}
