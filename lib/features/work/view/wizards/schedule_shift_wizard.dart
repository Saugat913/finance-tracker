import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';

class ScheduleShiftWizard extends StatefulWidget {
  const ScheduleShiftWizard({super.key});

  @override
  State<ScheduleShiftWizard> createState() => _ScheduleShiftWizardState();
}

class _ScheduleShiftWizardState extends State<ScheduleShiftWizard> {
  int _step = 0;
  int? _jobId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  bool _fixedEnd = true;

  @override
  void initState() {
    super.initState();
    final vm = getIt<WorkViewModel>();
    if (vm.jobs.isNotEmpty) {
      _jobId = vm.jobs.first.id;
    }
  }

  void _onNext() {
    if (_step == 0) {
      if (_jobId == null) return;
      setState(() => _step = 1);
    } else if (_step == 1) {
      setState(() => _step = 2);
    } else {
      _save();
    }
  }

  Future<void> _save() async {
    if (_jobId == null) return;
    final viewModel = getIt<WorkViewModel>();

    final startAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endAt = _fixedEnd
        ? DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _endTime.hour,
            _endTime.minute,
          )
        : null;

    final id = await viewModel.scheduleShift(
      jobId: _jobId!,
      startAt: startAt,
      endAt: endAt,
    );

    if (mounted) {
      showToast(
        context,
        'Shift scheduled',
        actionLabel: 'Undo',
        onAction: () async {
          await viewModel.shiftRepo.delete(id);
        },
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<WorkViewModel>();
    final jobs = viewModel.jobs;
    if (jobs.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: EmptyState(
            icon: HugeIcons.strokeRoundedBriefcase01,
            title: 'No jobs yet',
            message: 'You need to add a job before scheduling a shift.',
            actionLabel: 'Add a job',
            onAction: () {
              context.pop();
              context.push(AppRoutes.addJob);
            },
          ),
        ),
      );
    }

    return switch (_step) {
      0 => WizardScaffold(
          step: 0,
          steps: 3,
          title: 'Which job is this shift for?',
          subtitle: 'Pick one.',
          primaryLabel: 'Next',
          onPrimary: _jobId != null ? _onNext : null,
          onClose: () => context.pop(),
          child: Column(
            children: [
              for (final job in jobs) ...[
                OptionTile(
                  title: job.name,
                  subtitle: '${MoneyFormatter.format(job.hourlyRateMinor, job.currencyCode)} / hour',
                  selected: _jobId == job.id,
                  onTap: () => setState(() => _jobId = job.id),
                ),
                const SizedBox(height: AppSpace.sm),
              ],
            ],
          ),
        ),
      1 => WizardScaffold(
          step: 1,
          steps: 3,
          title: 'Which day?',
          subtitle: 'Pick the shift date.',
          onBack: () => setState(() => _step = 0),
          onClose: () => context.pop(),
          primaryLabel: 'Next',
          onPrimary: _onNext,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  for (var i = 0; i < 7; i++) ...[
                    Builder(builder: (context) {
                      final day = DateTime.now().add(Duration(days: i));
                      final isSelected = AppDate.dateOnly(day) == AppDate.dateOnly(_selectedDate);
                      return ChoicePill(
                        AppDate.weekdayDay(day),
                        selected: isSelected,
                        onTap: () => setState(() => _selectedDate = day),
                      );
                    }),
                  ],
                ],
              ),
              const SizedBox(height: AppSpace.xl),
              OptionTile(
                title: 'Just this day',
                selected: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      _ => WizardScaffold(
          step: 2,
          steps: 3,
          title: 'What time is the shift?',
          subtitle: '${viewModel.jobsById[_jobId]?.name ?? "Job"} · ${AppDate.short(_selectedDate)}',
          onBack: () => setState(() => _step = 1),
          onClose: () => context.pop(),
          primaryLabel: 'Save shift',
          onPrimary: _save,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showTimePicker(context: context, initialTime: _startTime);
                        if (picked != null) setState(() => _startTime = picked);
                      },
                      child: Text('Starts: ${_startTime.format(context)}'),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  if (_fixedEnd)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: _endTime);
                          if (picked != null) setState(() => _endTime = picked);
                        },
                        child: Text('Ends: ${_endTime.format(context)}'),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.xl),
              SwitchRow(
                title: 'Fixed end',
                subtitle: _fixedEnd
                    ? 'Shift ends automatically at selected time'
                    : 'With an open end, you finish the shift yourself.',
                value: _fixedEnd,
                onChanged: (val) => setState(() => _fixedEnd = val),
              ),
            ],
          ),
        ),
    };
  }
}
