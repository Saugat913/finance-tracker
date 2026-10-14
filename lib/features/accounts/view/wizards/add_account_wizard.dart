import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/accounts/data/model/account_type.dart';
import 'package:finance_tracker/features/accounts/viewmodels/accounts_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class AddAccountWizard extends StatefulWidget {
  const AddAccountWizard({super.key});

  @override
  State<AddAccountWizard> createState() => _AddAccountWizardState();
}

class _AddAccountWizardState extends State<AddAccountWizard> {
  int _step = 0;
  AccountType _selectedType = AccountType.bank;
  late final TextEditingController _nameController;
  final _balanceController = TextEditingController(text: '1250.00');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _defaultNameFor(_selectedType));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  String _defaultNameFor(AccountType type) => switch (type) {
        AccountType.cash => 'Cash',
        AccountType.bank => 'Everyday account',
        AccountType.wallet => 'Digital wallet',
        AccountType.savings => 'Savings',
      };

  void _onNext() {
    if (_step == 0) {
      setState(() {
        _nameController.text = _defaultNameFor(_selectedType);
        _step = 1;
      });
    } else {
      _save();
    }
  }

  Future<void> _save() async {
    final viewModel = getIt<AccountsViewModel>();
    final balanceDouble = double.tryParse(_balanceController.text.trim()) ?? 0.0;
    final balanceMinor = (balanceDouble * 100).round();

    final id = await viewModel.addAccount(
      name: _nameController.text.trim().isEmpty ? _defaultNameFor(_selectedType) : _nameController.text.trim(),
      type: _selectedType,
      openingBalanceMinor: balanceMinor,
    );

    if (mounted) {
      showToast(
        context,
        'Account added',
        actionLabel: 'Undo',
        onAction: () async {
          await viewModel.deleteAccount(id);
        },
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = getIt<AccountsViewModel>().baseCurrency;

    return switch (_step) {
      0 => WizardScaffold(
          step: 0,
          steps: 2,
          title: 'What kind of account?',
          subtitle: 'Start with the one you use most.',
          confirmClose: true,
          primaryLabel: 'Next',
          onPrimary: _onNext,
          onClose: () => context.pop(),
          child: Column(
            children: [
              OptionTile(
                title: 'Cash',
                subtitle: 'Money in your pocket',
                icon: HugeIcons.strokeRoundedCoins01,
                selected: _selectedType == AccountType.cash,
                onTap: () => setState(() => _selectedType = AccountType.cash),
              ),
              const SizedBox(height: AppSpace.sm),
              OptionTile(
                title: 'Bank account',
                subtitle: 'Everyday spending',
                icon: HugeIcons.strokeRoundedBank,
                selected: _selectedType == AccountType.bank,
                onTap: () => setState(() => _selectedType = AccountType.bank),
              ),
              const SizedBox(height: AppSpace.sm),
              OptionTile(
                title: 'Digital wallet',
                subtitle: 'Apps and cards',
                icon: HugeIcons.strokeRoundedWallet01,
                selected: _selectedType == AccountType.wallet,
                onTap: () => setState(() => _selectedType = AccountType.wallet),
              ),
              const SizedBox(height: AppSpace.sm),
              OptionTile(
                title: 'Savings',
                subtitle: 'Money set aside',
                icon: HugeIcons.strokeRoundedPiggyBank,
                selected: _selectedType == AccountType.savings,
                onTap: () => setState(() => _selectedType = AccountType.savings),
              ),
            ],
          ),
        ),
      _ => WizardScaffold(
          step: 1,
          steps: 2,
          title: 'What is the balance right now?',
          subtitle: 'Roughly is fine. You can fix it later.',
          onBack: () => setState(() => _step = 0),
          onClose: () => context.pop(),
          confirmClose: true,
          primaryLabel: 'Save account',
          onPrimary: _save,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UnderlineField(
                label: 'Name',
                hint: _defaultNameFor(_selectedType),
                controller: _nameController,
                autofocus: true,
              ),
              const SizedBox(height: AppSpace.xl),
              UnderlineField(
                label: 'Balance',
                hint: '$currency 1,250.00',
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
    };
  }
}
