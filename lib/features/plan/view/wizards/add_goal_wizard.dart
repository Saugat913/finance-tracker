import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/plan/viewmodels/plan_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class AddGoalWizard extends StatefulWidget {
  const AddGoalWizard({super.key});

  @override
  State<AddGoalWizard> createState() => _AddGoalWizardState();
}

class _AddGoalWizardState extends State<AddGoalWizard> {
  int _step = 0;
  String _category = 'Emergency fund';
  final _customNameController = TextEditingController();
  final _targetController = TextEditingController(text: '5000.00');
  final _alreadySavedController = TextEditingController(text: '0.00');

  int _months = 6;
  DateTime? _customDate;
  bool _remindMonthly = true;

  @override
  void dispose() {
    _customNameController.dispose();
    _targetController.dispose();
    _alreadySavedController.dispose();
    super.dispose();
  }

  String get _goalName {
    if (_category == 'Something else') {
      return _customNameController.text.trim().isEmpty ? 'My goal' : _customNameController.text.trim();
    }
    return _category;
  }

  void _onNext() {
    if (_step == 0) {
      setState(() => _step = 1);
    } else if (_step == 1) {
      setState(() => _step = 2);
    } else {
      _save();
    }
  }

  Future<void> _save() async {
    final viewModel = getIt<PlanViewModel>();
    final target = (double.tryParse(_targetController.text.trim()) ?? 1000.0) * 100;
    final saved = (double.tryParse(_alreadySavedController.text.trim()) ?? 0.0) * 100;

    final targetDate = _customDate ?? DateTime.now().add(Duration(days: _months * 30));

    await viewModel.addGoal(
      name: _goalName,
      targetAmountMinor: target.round(),
      initialSavedMinor: saved.round(),
      targetDate: targetDate,
      category: _category,
    );

    if (mounted) {
      showToast(context, 'Goal created', actionLabel: 'View');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = getIt<PlanViewModel>().baseCurrency;
    final text = Theme.of(context).textTheme;

    final targetDouble = double.tryParse(_targetController.text) ?? 5000.0;
    final savedDouble = double.tryParse(_alreadySavedController.text) ?? 0.0;
    final remaining = (targetDouble - savedDouble).clamp(0.0, double.infinity);
    final monthlyNeed = (remaining / _months);

    return switch (_step) {
      0 => WizardScaffold(
          step: 0,
          steps: 3,
          title: 'What are you saving for?',
          subtitle: 'Pick the closest one.',
          confirmClose: true,
          primaryLabel: 'Next',
          onPrimary: _onNext,
          onClose: () => context.pop(),
          child: Column(
            children: [
              OptionTile(
                title: 'Emergency fund',
                subtitle: 'A cushion for surprises',
                selected: _category == 'Emergency fund',
                onTap: () => setState(() => _category = 'Emergency fund'),
              ),
              const SizedBox(height: AppSpace.sm),
              OptionTile(
                title: 'Something to buy',
                subtitle: 'A laptop, a bike, a gift',
                selected: _category == 'Something to buy',
                onTap: () => setState(() => _category = 'Something to buy'),
              ),
              const SizedBox(height: AppSpace.sm),
              OptionTile(
                title: 'A trip',
                subtitle: 'Somewhere you want to go',
                selected: _category == 'A trip',
                onTap: () => setState(() => _category = 'A trip'),
              ),
              const SizedBox(height: AppSpace.sm),
              OptionTile(
                title: 'Something else',
                subtitle: 'Name it yourself',
                selected: _category == 'Something else',
                onTap: () => setState(() => _category = 'Something else'),
              ),
              if (_category == 'Something else') ...[
                const SizedBox(height: AppSpace.md),
                UnderlineField(
                  label: 'Goal name',
                  hint: 'e.g. Tuition',
                  controller: _customNameController,
                  autofocus: true,
                ),
              ],
            ],
          ),
        ),
      1 => WizardScaffold(
          step: 1,
          steps: 3,
          title: 'How much do you need?',
          subtitle: 'A rough number is fine.',
          onBack: () => setState(() => _step = 0),
          onClose: () => context.pop(),
          confirmClose: true,
          primaryLabel: 'Next',
          onPrimary: _onNext,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UnderlineField(
                label: 'Target',
                hint: '$currency 5,000',
                controller: _targetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpace.xl),
              UnderlineField(
                label: 'Already saved',
                hint: '$currency 0',
                controller: _alreadySavedController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
      _ => WizardScaffold(
          step: 2,
          steps: 3,
          title: 'By when?',
          subtitle: 'We will work out the monthly amount.',
          onBack: () => setState(() => _step = 1),
          onClose: () => context.pop(),
          confirmClose: true,
          primaryLabel: 'Save goal',
          onPrimary: _save,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  for (final m in [3, 6, 12])
                    ChoicePill(
                      '$m mo',
                      selected: _months == m && _customDate == null,
                      onTap: () {
                        setState(() {
                          _months = m;
                          _customDate = null;
                        });
                      },
                    ),
                  ChoicePill(
                    _customDate != null ? AppDate.short(_customDate!) : 'Date',
                    selected: _customDate != null,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 90)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (picked != null) {
                        setState(() {
                          _customDate = picked;
                          final diffDays = picked.difference(DateTime.now()).inDays;
                          _months = (diffDays / 30).clamp(1, 120).round();
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.xl),

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('To get there', style: text.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      '${MoneyFormatter.format((monthlyNeed * 100).round(), currency)} a month',
                      style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.md),

              SwitchRow(
                title: 'Remind me each month',
                subtitle: 'A nudge to set money aside',
                value: _remindMonthly,
                onChanged: (val) => setState(() => _remindMonthly = val),
              ),
            ],
          ),
        ),
    };
  }
}
