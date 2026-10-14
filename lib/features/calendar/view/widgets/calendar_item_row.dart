import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/calendar/viewmodels/calendar_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class CalendarItemRow extends StatelessWidget {
  const CalendarItemRow({super.key, required this.item});

  final CalendarItem item;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final icon = switch (item.type) {
      CalendarItemType.shift => HugeIcons.strokeRoundedClock01,
      CalendarItemType.bill => HugeIcons.strokeRoundedReceiptText,
      CalendarItemType.goal => HugeIcons.strokeRoundedTarget02,
    };

    return Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Row(
        children: [
          IconTile(icon, size: 36),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: text.titleSmall),
                Text(item.subtitle, style: text.bodySmall),
              ],
            ),
          ),
          MoneyText(
            item.isIncome ? item.amountMinor : -item.amountMinor,
            item.currencyCode,
            signed: true,
            style: text.titleSmall,
          ),
        ],
      ),
    );
  }
}
