import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/core/utils/dates.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/money/viewmodels/money_view_model.dart';
import 'package:finance_tracker/features/shared/data/categories.dart';
import 'package:finance_tracker/features/shared/data/currency.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class AddTransactionWizard extends StatefulWidget {
  const AddTransactionWizard({super.key});

  @override
  State<AddTransactionWizard> createState() => _AddTransactionWizardState();
}

class _AddTransactionWizardState extends State<AddTransactionWizard> {
  int _step = 0;
  TransactionType _type = TransactionType.expense;
  final _amountController = TextEditingController();
  String _categoryKey = 'eating_out';
  String? _merchant = "Domino's";
  final _customMerchantController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();

  bool _isSaving = false;
  int? _selectedAccountId;

  @override
  void dispose() {
    _amountController.dispose();
    _customMerchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_step == 0) {
      final amount = double.tryParse(_amountController.text) ?? 0;
      if (amount <= 0) {
        showToast(context, 'Please enter an amount');
        return;
      }
      setState(() => _step = 1);
    } else {
      _save();
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final viewModel = getIt<MoneyViewModel>();
      final amountDouble = double.tryParse(_amountController.text) ?? 0;
      final amountMinor = (amountDouble * 100).round();
      if (amountMinor <= 0) {
        showToast(context, 'Please enter a valid amount');
        setState(() => _isSaving = false);
        return;
      }

      int accountId;
      if (viewModel.accounts.isNotEmpty) {
        accountId = _selectedAccountId ?? viewModel.accounts.first.id;
      } else {
        accountId = await viewModel.ensureDefaultAccount();
      }

      final category = TransactionCategories.fromValue(_categoryKey, _type);
      final effectiveMerchant = _merchant == 'Other'
          ? _customMerchantController.text.trim()
          : _merchant;

      final id = await viewModel.addTransaction(
        accountId: accountId,
        amountMinor: amountMinor,
        type: _type,
        category: category.label,
        merchant: effectiveMerchant?.isNotEmpty == true ? effectiveMerchant : null,
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        occurredAt: _date,
      );

      if (mounted) {
        showToast(
          context,
          _type == TransactionType.expense ? 'Expense added' : 'Income added',
          actionLabel: 'Undo',
          onAction: () async {
            await viewModel.deleteTransaction(id);
          },
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        showToast(context, 'Could not save: $e');
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<MoneyViewModel>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final currencySymbol = Currency.fromCode(viewModel.baseCurrency).symbol;

    final categories = _type == TransactionType.expense
        ? [
            TransactionCategories.find('groceries', TransactionType.expense)!,
            TransactionCategories.find('eating_out', TransactionType.expense)!,
            TransactionCategories.find('entertainment', TransactionType.expense)!,
            TransactionCategories.find('transport', TransactionType.expense)!,
            TransactionCategories.find('bills', TransactionType.expense)!,
          ]
        : TransactionCategories.forType(TransactionType.income);

    final merchants = TransactionCategories.merchantsFor(_categoryKey);

    return switch (_step) {
      0 => WizardScaffold(
          step: 0,
          steps: 2,
          title: 'How much was it?',
          subtitle: 'Type the amount. Your keyboard will do the rest.',
          confirmClose: _amountController.text.trim().isNotEmpty,
          discardTitle: _type == TransactionType.expense
              ? 'Discard this expense?'
              : 'Discard this income?',
          primaryLabel: 'Next',
          onPrimary: _onNext,
          onClose: () => context.pop(),
          child: Column(
            children: [
              SegmentedTabs<TransactionType>(
                options: const {
                  TransactionType.expense: 'Expense',
                  TransactionType.income: 'Income',
                },
                value: _type,
                onChanged: (type) {
                  setState(() {
                    _type = type;
                    _categoryKey = _type == TransactionType.expense ? 'eating_out' : 'shift_pay';
                    final newMerchants = TransactionCategories.merchantsFor(_categoryKey);
                    _merchant = newMerchants.isNotEmpty ? newMerchants.first : null;
                  });
                },
              ),
              const SizedBox(height: AppSpace.xxl),
              BigAmountField(
                currencySymbol: currencySymbol,
                controller: _amountController,
                autofocus: true,
              ),
            ],
          ),
        ),
      _ => WizardScaffold(
          step: 1,
          steps: 2,
          title: 'What was it for?',
          subtitle: 'Pick a category and where you spent it.',
          onBack: () => setState(() => _step = 0),
          onClose: () => context.pop(),
          primaryLabel: _isSaving
              ? 'Saving...'
              : (_type == TransactionType.expense ? 'Save expense' : 'Save income'),
          onPrimary: _save,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category ChoicePills
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  for (final cat in categories)
                    ChoicePill(
                      cat.label,
                      selected: _categoryKey == cat.value,
                      onTap: () {
                        setState(() {
                          _categoryKey = cat.value;
                          final mList = TransactionCategories.merchantsFor(_categoryKey);
                          _merchant = mList.isNotEmpty ? mList.first : null;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.xl),

              // "Where?" merchant card grid (PDF pages 33-34)
              if (merchants.isNotEmpty) ...[
                Text(
                  'Where?',
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = (constraints.maxWidth - 3 * AppSpace.sm) / 4;
                    return Wrap(
                      spacing: AppSpace.sm,
                      runSpacing: AppSpace.sm,
                      children: [
                        for (final m in merchants)
                          SizedBox(
                            width: itemWidth,
                            child: _MerchantCard(
                              name: m,
                              selected: _merchant == m,
                              onTap: () {
                                setState(() {
                                  _merchant = _merchant == m ? null : m;
                                });
                              },
                            ),
                          ),
                        SizedBox(
                          width: itemWidth,
                          child: _MerchantCard(
                            name: 'Other',
                            isOther: true,
                            selected: _merchant == 'Other',
                            onTap: () {
                              setState(() {
                                _merchant = _merchant == 'Other' ? null : 'Other';
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (_merchant == 'Other') ...[
                  const SizedBox(height: AppSpace.md),
                  UnderlineField(
                    label: 'Merchant name',
                    hint: 'e.g. Local Bakery',
                    controller: _customMerchantController,
                  ),
                ],
                const SizedBox(height: AppSpace.xl),
              ],

              // Multi-account picker (if multiple accounts exist)
              if (viewModel.accounts.length > 1) ...[
                Text(
                  'Account',
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    for (final acc in viewModel.accounts)
                      ChoicePill(
                        acc.name,
                        selected: (_selectedAccountId ?? viewModel.accounts.first.id) == acc.id,
                        onTap: () => setState(() => _selectedAccountId = acc.id),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.xl),
              ],

              // Date and Note Card (PDF pages 33-34)
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setState(() => _date = picked);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.lg,
                          vertical: AppSpace.lg,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Date',
                              style: text.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              AppDate.dateOnly(_date) == AppDate.dateOnly(DateTime.now())
                                  ? 'Today'
                                  : AppDate.short(_date),
                              style: text.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const RowDivider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.lg,
                        vertical: AppSpace.sm,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Note',
                            style: text.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: TextField(
                              controller: _noteController,
                              textAlign: TextAlign.right,
                              style: text.bodyMedium?.copyWith(
                                color: scheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Optional',
                                hintStyle: text.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: AppSpace.sm,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    };
  }
}

class _MerchantCard extends StatelessWidget {
  const _MerchantCard({
    required this.name,
    required this.selected,
    required this.onTap,
    this.isOther = false,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;
  final bool isOther;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? scheme.onSurface : scheme.outlineVariant,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpace.md,
          horizontal: AppSpace.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isOther)
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F1F2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.add, size: 20, color: scheme.onSurface),
              )
            else
              LetterAvatar(name, size: 40, isCircle: true),
            const SizedBox(height: AppSpace.sm),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: text.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
