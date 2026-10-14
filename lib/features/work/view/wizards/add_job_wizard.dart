import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';
import 'package:finance_tracker/features/work/viewmodels/work_view_model.dart';

class AddJobWizard extends StatefulWidget {
  const AddJobWizard({super.key});

  @override
  State<AddJobWizard> createState() => _AddJobWizardState();
}

class _AddJobWizardState extends State<AddJobWizard> {
  int _step = 0;
  final _nameController = TextEditingController();
  final _rateController = TextEditingController(text: '25.00');

  String _payType = 'hourly';
  final Set<int> _selectedDays = {1, 5}; // Monday and Friday default

  static const _suggestions = ['Café', 'Warehouse', 'Tutoring', 'Delivery'];
  static const _days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_step == 0) {
      if (_nameController.text.trim().isEmpty) return;
      setState(() => _step = 1);
    } else if (_step == 1) {
      setState(() => _step = 2);
    } else {
      _save();
    }
  }

  Future<void> _save() async {
    final viewModel = getIt<WorkViewModel>();
    final rateDouble = double.tryParse(_rateController.text.trim()) ?? 25.0;
    final rateMinor = (rateDouble * 100).round();

    await viewModel.addJob(
      name: _nameController.text.trim(),
      hourlyRateMinor: rateMinor,
    );

    if (mounted) {
      showToast(context, 'Job saved', actionLabel: 'View');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final currency = getIt<WorkViewModel>().baseCurrency;

    return switch (_step) {
      0 => WizardScaffold(
          step: 0,
          steps: 3,
          title: 'What is the job called?',
          subtitle: 'A name you will recognise at a glance.',
          confirmClose: true,
          primaryLabel: 'Next',
          onPrimary: _nameController.text.trim().isNotEmpty ? _onNext : null,
          onClose: () => context.pop(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UnderlineField(
                label: 'Name',
                hint: 'e.g. Café',
                controller: _nameController,
                autofocus: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpace.xl),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  for (final s in _suggestions)
                    ChoicePill(
                      s,
                      selected: _nameController.text == s,
                      onTap: () {
                        setState(() {
                          _nameController.text = s;
                        });
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      1 => WizardScaffold(
          step: 1,
          steps: 3,
          title: 'How do you get paid?',
          subtitle: 'This keeps your forecasts accurate.',
          onBack: () => setState(() => _step = 0),
          onClose: () => context.pop(),
          confirmClose: true,
          primaryLabel: 'Next',
          onPrimary: _onNext,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OptionTile(
                title: 'Hourly',
                subtitle: 'Paid for the hours you work',
                selected: _payType == 'hourly',
                onTap: () => setState(() => _payType = 'hourly'),
              ),
              const SizedBox(height: AppSpace.sm),
              OptionTile(
                title: 'Per shift',
                subtitle: 'Same amount every shift',
                selected: _payType == 'shift',
                onTap: () => setState(() => _payType = 'shift'),
              ),
              const SizedBox(height: AppSpace.sm),
              OptionTile(
                title: 'Salary',
                subtitle: 'Fixed amount each pay period',
                selected: _payType == 'salary',
                onTap: () => setState(() => _payType = 'salary'),
              ),
              const SizedBox(height: AppSpace.xl),
              UnderlineField(
                label: 'Rate',
                hint: '$currency 25.00',
                controller: _rateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
      _ => WizardScaffold(
          step: 2,
          steps: 3,
          title: 'Which days do you usually work?',
          subtitle: 'Pick the days. Times are set per shift.',
          onBack: () => setState(() => _step = 1),
          onClose: () => context.pop(),
          confirmClose: true,
          primaryLabel: 'Save job',
          onPrimary: _save,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  for (var i = 0; i < _days.length; i++)
                    ChoicePill(
                      _days[i],
                      selected: _selectedDays.contains(i),
                      onTap: () {
                        setState(() {
                          if (_selectedDays.contains(i)) {
                            _selectedDays.remove(i);
                          } else {
                            _selectedDays.add(i);
                          }
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.xl),
              Text(
                '${_selectedDays.length} days selected per week',
                style: text.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
    };
  }
}
