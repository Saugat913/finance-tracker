import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/settings/viewmodels/settings_view_model.dart';
import 'package:finance_tracker/features/shared/data/currency.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen> {
  bool _isSwitching = false;

  Future<void> _handleCurrencySelect(
    SettingsViewModel viewModel,
    Currency cur,
  ) async {
    if (_isSwitching) return;
    if (viewModel.baseCurrency == cur.code) {
      context.pop();
      return;
    }

    setState(() => _isSwitching = true);

    final error = await viewModel.switchBaseCurrencyWithConversion(cur.code);
    if (!mounted) return;
    setState(() => _isSwitching = false);

    if (error == 'NO_INTERNET') {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          insetPadding: const EdgeInsets.all(AppSpace.xl),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const IconTile(HugeIcons.strokeRoundedWifi01, size: 40),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Text(
                        'Internet required',
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                Text(
                  'An active internet connection is needed to fetch live exchange rates and convert your money accurately before switching currency.',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpace.xl),
                AppButton(
                  'Got it',
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (error != null) {
      if (!mounted) return;
      showToast(context, error);
    } else {
      if (!mounted) return;
      showToast(context, 'Switched to ${cur.name} (${cur.code}) with live rates');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = getIt<SettingsViewModel>();
    final text = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: const AppTopBar(title: 'Currency'),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.page,
                vertical: AppSpace.md,
              ),
              children: [
                Text(
                  'Base currency',
                  style: text.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                if (_isSwitching)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpace.md),
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  ),
                for (final cur in Currency.supported) ...[
                  OptionTile(
                    title: '${cur.symbol} · ${cur.name}',
                    subtitle: cur.code,
                    selected: viewModel.baseCurrency == cur.code,
                    onTap: () => _handleCurrencySelect(viewModel, cur),
                  ),
                  const SizedBox(height: AppSpace.sm),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
