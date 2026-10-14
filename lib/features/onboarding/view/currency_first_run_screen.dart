import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/app/routes.dart';
import 'package:finance_tracker/core/theme/app_dimensions.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/onboarding/viewmodels/onboarding_view_model.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';
import 'package:finance_tracker/features/shared/data/currency.dart';
import 'package:finance_tracker/features/shared/widgets/widgets.dart';

class CurrencyFirstRunScreen extends StatefulWidget {
  const CurrencyFirstRunScreen({super.key});

  @override
  State<CurrencyFirstRunScreen> createState() => _CurrencyFirstRunScreenState();
}

class _CurrencyFirstRunScreenState extends State<CurrencyFirstRunScreen> {
  late final OnboardingViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = OnboardingViewModel(
      settingsRepo: getIt<SettingsRepository>(),
      accountRepo: getIt<AccountRepository>(),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.page,
                vertical: AppSpace.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RoundIconButton(HugeIcons.strokeRoundedArrowLeft01, onPressed: () => context.go(AppRoutes.welcome)),
                  const SizedBox(height: AppSpace.xl),
                  Text('Which currency do you\nuse?', style: text.headlineMedium),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    'You can add a second one later.',
                    style: text.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final cur in Currency.supported.take(3)) ...[
                          OptionTile(
                            title: '${cur.symbol} · ${cur.name}',
                            subtitle: cur.code,
                            icon: HugeIcons.strokeRoundedWallet01,
                            selected: _viewModel.selectedCurrency == cur.code,
                            onTap: () => _viewModel.selectCurrency(cur.code),
                          ),
                          const SizedBox(height: AppSpace.md),
                        ],
                      ],
                    ),
                  ),
                  AppButton(
                    'Finish setup',
                    onPressed: () async {
                      await _viewModel.finishSetup();
                      if (context.mounted) {
                        context.go(AppRoutes.home);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
