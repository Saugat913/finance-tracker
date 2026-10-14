import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';

class LiveShiftScreen extends StatelessWidget {
  const LiveShiftScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<WorkViewModel>();

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final shift = viewModel.activeShift;
        final text = Theme.of(context).textTheme;
        final colors = context.colors;

        if (shift == null) {
          return Scaffold(
            appBar: AppBar(leading: const BackButton()),
            body: Center(
              child: EmptyState(
                icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                title: 'No active shift',
                message: 'You are not currently clocked into a shift.',
                actionLabel: 'Back to Work',
                onAction: () => context.go(AppRoutes.work),
              ),
            ),
          );
        }

        final job = viewModel.jobsById[shift.jobId];
        final startTime = DateTime.fromMillisecondsSinceEpoch(shift.startAt);
        final elapsed = viewModel.activeShiftElapsed;
        final liveEarnings = viewModel.activeShiftLiveEarnings;

        return Scaffold(
          appBar: AppBar(
            leading: BackButton(onPressed: () => context.go(AppRoutes.work)),
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Started ${AppDate.timeOnly(startTime)}', style: text.bodySmall),
                      const Spacer(),
                      const StatusChip('In progress', tone: ChipTone.success),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(job?.name ?? 'Shift', style: text.headlineMedium),
                  const SizedBox(height: AppSpace.xxl),

                  Center(
                    child: Column(
                      children: [
                        Text(
                          _formatTimer(elapsed),
                          style: text.displayLarge?.copyWith(
                            fontFamily: 'RedditMono',
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: AppSpace.md),
                        if (liveEarnings != null)
                          Text(
                            '≈ ${MoneyFormatter.format(liveEarnings.earningsMinor, job?.currencyCode ?? viewModel.baseCurrency)} earned so far',
                            style: text.bodyMedium?.copyWith(
                              color: colors.income,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const Spacer(),
                  AppButton(
                    'End shift',
                    kind: AppButtonKind.danger,
                    onPressed: () async {
                      final confirmed = await showConfirmDialog(
                        context,
                        title: 'End shift now?',
                        message: '${job?.name ?? "Shift"} · ${elapsed.inHours} h ${elapsed.inMinutes % 60} m worked. '
                            'You can edit the times afterwards.',
                        confirmLabel: 'End shift',
                        cancelLabel: 'Keep working',
                      );
                      if (confirmed && context.mounted) {
                        final earnings = await viewModel.endShift(shift.id);
                        if (context.mounted) {
                          context.go(AppRoutes.shiftDone(shift.id), extra: earnings);
                        }
                      }
                    },
                  ),
                  const SizedBox(height: AppSpace.sm),
                  AppButton(
                    'Edit start time',
                    kind: AppButtonKind.outline,
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(startTime),
                      );
                      if (picked != null) {
                        final newStart = DateTime(
                          startTime.year,
                          startTime.month,
                          startTime.day,
                          picked.hour,
                          picked.minute,
                        );
                        await viewModel.shiftRepo.update(shift.id, startAt: newStart);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTimer(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
