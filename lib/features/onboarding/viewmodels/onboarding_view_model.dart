import 'package:flutter/foundation.dart';
import 'package:finance_tracker/features/accounts/data/model/account_type.dart';
import 'package:finance_tracker/features/accounts/data/repository/account_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';

class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel({
    required this.settingsRepo,
    required this.accountRepo,
  });

  final SettingsRepository settingsRepo;
  final AccountRepository accountRepo;

  String _selectedCurrency = 'AUD';
  String get selectedCurrency => _selectedCurrency;

  void selectCurrency(String code) {
    _selectedCurrency = code;
    notifyListeners();
  }

  Future<void> finishSetup() async {
    await settingsRepo.setBaseCurrency(_selectedCurrency);
    final accounts = await accountRepo.watchAll().first;
    if (accounts.isEmpty) {
      await accountRepo.add(
        name: 'Everyday',
        type: AccountType.bank,
        openingBalanceMinor: 0,
        currencyCode: _selectedCurrency,
      );
    } else {
      final first = accounts.first;
      if (first.name == 'Everyday') {
        await accountRepo.update(first.id, currencyCode: _selectedCurrency);
      }
    }
    await settingsRepo.completeOnboarding();
  }
}
