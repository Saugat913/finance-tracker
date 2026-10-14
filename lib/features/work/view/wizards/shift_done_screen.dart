import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';

class ShiftDoneScreen extends StatelessWidget {
  const ShiftDoneScreen({super.key, required this.shiftId, this.earnings});

  final int shiftId;
  final ShiftEarnings? earnings;

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<WorkViewModel>();
    final text = Theme.of(context).textTheme;
    final colors = context.colors;

    final shift = viewModel.shifts.firstWhere((s) => s.id == shiftId, orElse: () => viewModel.shifts.first);
    final job = viewModel.jobsById[shift.jobId];

    final calculated = earnings ??
        (job != null ? ShiftEarnings.forShift(shift, job) : null);

    final hours = (calculated?.workedMinutes ?? 0) ~/ 60;
    final minutes = (calculated?.workedMinutes ?? 0) % 60;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpace.xxl),
              Text('Shift complete', style: text.headlineMedium),
              const SizedBox(height: AppSpace.xl),

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Job', style: text.bodySmall),
                    const SizedBox(height: 2),
                    Text(job?.name ?? 'Shift', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: AppSpace.lg),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Duration', style: text.bodySmall),
                              const SizedBox(height: 2),
                              Text(
                                '${hours}h ${minutes}m',
                                style: text.titleMedium?.copyWith(
                                  fontFamily: 'RedditMono',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Earned', style: text.bodySmall),
                              const SizedBox(height: 2),
                              Text(
                                '+${MoneyFormatter.format(calculated?.earningsMinor ?? 0, job?.currencyCode ?? viewModel.baseCurrency)}',
                                style: text.titleMedium?.copyWith(
                                  color: colors.income,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),
              AppButton(
                'Done',
                onPressed: () => context.go(AppRoutes.work),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
