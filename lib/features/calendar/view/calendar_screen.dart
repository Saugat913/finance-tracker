import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/features/calendar/view/widgets/calendar_item_row.dart';
import 'package:finance_tracker/features/calendar/viewmodels/calendar_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<CalendarViewModel>();

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final text = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;
        final items = viewModel.agendaItems;

        return TabPage(
          title: 'Calendar',
          overline: AppDate.monthYear(viewModel.selectedDate),
          children: [
            // Weekday day strip
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.md, horizontal: AppSpace.xs),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (final day in viewModel.weekStrip) ...[
                    _DayCell(
                      date: day,
                      isSelected: AppDate.dateOnly(day) == viewModel.selectedDate,
                      hasDot: viewModel.hasEventsOn(day),
                      onTap: () => viewModel.selectDate(day),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpace.xl),

            // Agenda or empty state
            if (items.isEmpty)
              EmptyState(
                icon: HugeIcons.strokeRoundedCalendar03,
                title: 'Nothing scheduled',
                message: 'Shifts, bills and goal top-ups will show up here.',
                actionLabel: 'Add a shift',
                onAction: () => context.push(AppRoutes.scheduleShift),
              )
            else ...[
              // Group items by day
              for (final group in _groupItemsByDate(items)) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                  child: Text(
                    _formatGroupHeader(group.date),
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < group.items.length; i++) ...[
                        if (i > 0) const RowDivider(),
                        CalendarItemRow(item: group.items[i]),
                      ],
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

  String _formatGroupHeader(DateTime date) {
    final today = AppDate.dateOnly(DateTime.now());
    final d = AppDate.dateOnly(date);
    if (d == today) {
      return 'Today · ${AppDate.weekdayDay(date)}';
    }
    return AppDate.weekdayDay(date);
  }

  List<_DateGroup> _groupItemsByDate(List<CalendarItem> items) {
    final groups = <DateTime, List<CalendarItem>>{};
    for (final item in items) {
      final key = AppDate.dateOnly(item.date);
      groups.putIfAbsent(key, () => []).add(item);
    }
    return groups.entries
        .map((e) => _DateGroup(date: e.key, items: e.value))
        .toList();
  }
}

class _DateGroup {
  _DateGroup({required this.date, required this.items});
  final DateTime date;
  final List<CalendarItem> items;
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isSelected,
    required this.hasDot,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool hasDot;
  final VoidCallback onTap;

  static const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;
    final dayLetter = _dayLetters[date.weekday - 1];

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(
            dayLetter,
            style: text.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? scheme.onSurface : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${date.day}',
              style: text.titleSmall?.copyWith(
                color: isSelected ? scheme.surface : scheme.onSurface,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: hasDot ? colors.income : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
