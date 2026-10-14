import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/theme/app_color_scheme.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class WorkScreen extends StatelessWidget {
  const WorkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<WorkViewModel>();

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final text = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;
        final colors = context.colors;
        final activeShift = viewModel.activeShift;

        return TabPage(
          title: 'Work',
          overline: 'Shifts and jobs',
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
            // Active shift banner (if clocked in)
            if (activeShift != null) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('In progress', style: text.bodySmall?.copyWith(color: colors.income)),
                        const Spacer(),
                        const StatusChip('Active', tone: ChipTone.success),
                      ],
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      viewModel.jobsById[activeShift.jobId]?.name ?? 'Shift',
                      style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpace.md),
                    Text(
                      _formatDuration(viewModel.activeShiftElapsed),
                      style: text.displaySmall?.copyWith(
                        fontFamily: 'RedditMono',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            'View live shift',
                            onPressed: () => context.push(AppRoutes.liveShift),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.xl),
            ],

            if (viewModel.jobs.isEmpty)
              EmptyState(
                icon: HugeIcons.strokeRoundedBriefcase01,
                title: 'No jobs yet',
                message: 'Add a job to start tracking shifts and pay.',
                actionLabel: 'Add a job',
                onAction: () => context.push(AppRoutes.addJob),
              )
            else ...[
              Text(
                'Which job are you starting?',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpace.md),

              for (final job in viewModel.jobs) ...[
                OptionTile(
                  title: job.name,
                  subtitle: '${MoneyFormatter.format(job.hourlyRateMinor, job.currencyCode)} / hour',
                  selected: viewModel.selectedJob?.id == job.id,
                  icon: HugeIcons.strokeRoundedBriefcase01,
                  onTap: () => viewModel.selectJob(job.id),
                ),
                const SizedBox(height: AppSpace.sm),
              ],

              const SizedBox(height: AppSpace.sm),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      'Add a job',
                      icon: HugeIcons.strokeRoundedPlusSign,
                      kind: AppButtonKind.outline,
                      onPressed: () => context.push(AppRoutes.addJob),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: AppButton(
                      'Schedule shift',
                      icon: HugeIcons.strokeRoundedCalendar03,
                      kind: AppButtonKind.outline,
                      onPressed: () => context.push(AppRoutes.scheduleShift),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),

              AppButton(
                'Start ${viewModel.selectedJob?.name ?? "shift"}',
                icon: HugeIcons.strokeRoundedPlay,
                onPressed: () => context.push(AppRoutes.startShift),
              ),

              const SizedBox(height: AppSpace.xxl),
              // Weekly stats card
              AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hours this week', style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                          const SizedBox(height: 4),
                          Text(
                            '${viewModel.hoursThisWeek.toStringAsFixed(1)} h',
                            style: text.headlineSmall?.copyWith(
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
                          Text('Shifts left', style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                          const SizedBox(height: 4),
                          Text(
                            '${viewModel.shiftsLeftThisWeek}',
                            style: text.headlineSmall?.copyWith(
                              fontFamily: 'RedditMono',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
