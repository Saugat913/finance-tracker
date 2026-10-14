import 'dart:convert';
import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/core/telemetry/telemetry_service.dart';

/// Handles bulk data operations: whole-database JSON export, import, and reset.
class DataRepository {
  DataRepository(this._db);

  final AppDatabase _db;

  /// Deletes all domain financial records (accounts, transactions, jobs, goals, etc.),
  /// but preserves essential app configuration (locale, theme mode, base currency).
  Future<void> eraseAll() async {
    await _db.transaction(() async {
      await _db.delete(_db.goalContributions).go();
      await _db.delete(_db.goals).go();
      await _db.delete(_db.shifts).go();
      await _db.delete(_db.jobs).go();
      await _db.delete(_db.recurringRules).go();
      await _db.delete(_db.transfers).go();
      await _db.delete(_db.transactions).go();
      await _db.delete(_db.accounts).go();
      await _db.delete(_db.exchangeRates).go();
    });
    TelemetryService.instance.trackEvent('data_erased');
  }

  /// Exports all financial tables to a JSON string.
  Future<String> exportJson() async {
    final accounts = await _db.select(_db.accounts).get();
    final transactions = await _db.select(_db.transactions).get();
    final transfers = await _db.select(_db.transfers).get();
    final recurringRules = await _db.select(_db.recurringRules).get();
    final jobs = await _db.select(_db.jobs).get();
    final shifts = await _db.select(_db.shifts).get();
    final goals = await _db.select(_db.goals).get();
    final contributions = await _db.select(_db.goalContributions).get();
    final rates = await _db.select(_db.exchangeRates).get();

    final payload = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'accounts': accounts.map((e) => e.toJson()).toList(),
      'transactions': transactions.map((e) => e.toJson()).toList(),
      'transfers': transfers.map((e) => e.toJson()).toList(),
      'recurringRules': recurringRules.map((e) => e.toJson()).toList(),
      'jobs': jobs.map((e) => e.toJson()).toList(),
      'shifts': shifts.map((e) => e.toJson()).toList(),
      'goals': goals.map((e) => e.toJson()).toList(),
      'goalContributions': contributions.map((e) => e.toJson()).toList(),
      'exchangeRates': rates.map((e) => e.toJson()).toList(),
    };

    TelemetryService.instance.trackEvent('data_exported', {
      'transactionsCount': transactions.length,
      'accountsCount': accounts.length,
    });

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Imports and overwrites data from an exported JSON string.
  Future<void> importJson(String jsonString) async {
    final Map<String, dynamic> data = jsonDecode(jsonString);

    await _db.transaction(() async {
      await eraseAll();

      if (data['accounts'] is List) {
        for (final item in data['accounts']) {
          await _db.into(_db.accounts).insert(
            Account.fromJson(item as Map<String, dynamic>),
          );
        }
      }

      if (data['transactions'] is List) {
        for (final item in data['transactions']) {
          await _db.into(_db.transactions).insert(
            Transaction.fromJson(item as Map<String, dynamic>),
          );
        }
      }

      if (data['transfers'] is List) {
        for (final item in data['transfers']) {
          await _db.into(_db.transfers).insert(
            Transfer.fromJson(item as Map<String, dynamic>),
          );
        }
      }

      if (data['recurringRules'] is List) {
        for (final item in data['recurringRules']) {
          await _db.into(_db.recurringRules).insert(
            RecurringRule.fromJson(item as Map<String, dynamic>),
          );
        }
      }

      if (data['jobs'] is List) {
        for (final item in data['jobs']) {
          await _db.into(_db.jobs).insert(
            Job.fromJson(item as Map<String, dynamic>),
          );
        }
      }

      if (data['shifts'] is List) {
        for (final item in data['shifts']) {
          await _db.into(_db.shifts).insert(
            Shift.fromJson(item as Map<String, dynamic>),
          );
        }
      }

      if (data['goals'] is List) {
        for (final item in data['goals']) {
          await _db.into(_db.goals).insert(
            Goal.fromJson(item as Map<String, dynamic>),
          );
        }
      }

      if (data['goalContributions'] is List) {
        for (final item in data['goalContributions']) {
          await _db.into(_db.goalContributions).insert(
            GoalContribution.fromJson(item as Map<String, dynamic>),
          );
        }
      }

      if (data['exchangeRates'] is List) {
        for (final item in data['exchangeRates']) {
          await _db.into(_db.exchangeRates).insert(
            ExchangeRate.fromJson(item as Map<String, dynamic>),
          );
        }
      }
    });

    TelemetryService.instance.trackEvent('data_imported');
  }
}
