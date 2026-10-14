import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';

class StartShiftSheet extends StatefulWidget {
  const StartShiftSheet({super.key});

  @override
  State<StartShiftSheet> createState() => _StartShiftSheetState();
}

class _StartShiftSheetState extends State<StartShiftSheet> {
  bool _remindClockOut = true;

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<WorkViewModel>();
    final job = viewModel.selectedJob;
    final text = Theme.of(context).textTheme;

    if (job == null) {
      return Scaffold(
        body: SafeArea(
          child: EmptyState(
            icon: HugeIcons.strokeRoundedBriefcase01,
            title: 'No jobs yet',
            message: 'Add a job first before starting a shift.',
            actionLabel: 'Add a job',
            onAction: () {
              context.pop();
              context.push(AppRoutes.addJob);
            },
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const AppTopBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Start this shift?', style: text.headlineMedium),
              const SizedBox(height: AppSpace.xl),

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Job', style: text.bodySmall),
                    const SizedBox(height: 4),
                    Text(job.name, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      '${MoneyFormatter.format(job.hourlyRateMinor, job.currencyCode)} / hour',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.md),

              AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Starts', style: text.bodySmall),
                          const SizedBox(height: 2),
                          Text('Now', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const StatusChip('Active', tone: ChipTone.neutral),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.md),

              SwitchRow(
                title: 'Remind me to clock out',
                subtitle: 'After 6 hours',
                value: _remindClockOut,
                onChanged: (val) => setState(() => _remindClockOut = val),
              ),

              const Spacer(),
              AppButton(
                'Start shift',
                onPressed: () async {
                  await viewModel.startShift(jobId: job.id);
                  if (context.mounted) {
                    context.go(AppRoutes.liveShift);
                  }
                },
              ),
              const SizedBox(height: AppSpace.sm),
              AppButton(
                'Not yet',
                kind: AppButtonKind.outline,
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
