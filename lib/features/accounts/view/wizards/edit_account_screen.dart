import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/money.dart';
import 'package:finance_tracker/features/accounts/data/model/account_type.dart';
import 'package:finance_tracker/features/accounts/viewmodels/accounts_view_model.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class EditAccountScreen extends StatefulWidget {
  const EditAccountScreen({super.key, required this.accountId});

  final int accountId;

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  late final TextEditingController _nameController;
  late AccountType _type;

  @override
  void initState() {
    super.initState();
    final viewModel = getIt<AccountsViewModel>();
    final account = viewModel.accounts.firstWhere(
      (a) => a.id == widget.accountId,
      orElse: () => viewModel.accounts.first,
    );
    _nameController = TextEditingController(text: account.name);
    _type = AccountType.fromValue(account.type);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<AccountsViewModel>();
    final account = viewModel.accounts.firstWhere(
      (a) => a.id == widget.accountId,
      orElse: () => viewModel.accounts.first,
    );
    final text = Theme.of(context).textTheme;
    final balanceMinor = viewModel.balanceOf(account.id);

    return Scaffold(
      appBar: AppTopBar(title: account.name),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UnderlineField(
                label: 'Name',
                controller: _nameController,
              ),
              const SizedBox(height: AppSpace.xl),

              Text('Type', style: text.bodySmall),
              const SizedBox(height: AppSpace.sm),
              Wrap(
                spacing: AppSpace.sm,
                children: [
                  for (final t in AccountType.values)
                    ChoicePill(
                      t.label,
                      selected: _type == t,
                      onTap: () => setState(() => _type = t),
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.xl),

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Balance', style: text.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      MoneyFormatter.format(balanceMinor, account.currencyCode),
                      style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      'Changing the balance adds an adjustment to your history.',
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.md),

              AppCard(
                child: Row(
                  children: [
                    Text('Currency', style: text.bodyMedium),
                    const Spacer(),
                    Text(account.currencyCode, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),

              const Spacer(),
              AppButton(
                'Save changes',
                onPressed: () async {
                  await viewModel.updateAccount(
                    widget.accountId,
                    name: _nameController.text.trim(),
                    type: _type,
                  );
                  if (context.mounted) {
                    showToast(context, 'Account updated');
                    context.pop();
                  }
                },
              ),
              const SizedBox(height: AppSpace.sm),
              AppButton(
                'Delete account',
                kind: AppButtonKind.danger,
                onPressed: () async {
                  final confirmed = await showConfirmDialog(
                    context,
                    title: 'Delete ${account.name}?',
                    message: 'Its transactions stay in your history but are no longer linked to an account.',
                    confirmLabel: 'Delete account',
                    cancelLabel: 'Cancel',
                  );
                  if (confirmed && context.mounted) {
                    await viewModel.deleteAccount(widget.accountId);
                    if (context.mounted) {
                      showToast(context, 'Account deleted');
                      context.pop();
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
