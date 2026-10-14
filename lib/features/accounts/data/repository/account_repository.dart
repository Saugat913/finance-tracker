import 'package:drift/drift.dart';

import 'package:finance_tracker/core/database/app_database.dart';
import 'package:finance_tracker/features/accounts/data/model/account_type.dart';
import 'package:finance_tracker/features/shared/data/repo_utils.dart';

class AccountRepository {
  AccountRepository(this._db);

  final AppDatabase _db;

  Stream<List<Account>> watchAll() =>
      (_db.select(_db.accounts)..orderBy([
        (a) => OrderingTerm.asc(a.isArchived),
        (a) => OrderingTerm.asc(a.name),
      ])).watch();

  Future<int> add({
    required String name,
    required AccountType type,
    required int openingBalanceMinor,
    required String currencyCode,
  }) {
    _validate(name);
    return _db
        .into(_db.accounts)
        .insert(
          AccountsCompanion.insert(
            name: name.trim(),
            type: type.value,
            openingBalanceMinor: openingBalanceMinor,
            currencyCode: currencyCode.toUpperCase(),
            createdAt: nowMs(),
            updatedAt: nowMs(),
          ),
        );
  }

  Future<void> update(
    int id, {
    String? name,
    AccountType? type,
    int? openingBalanceMinor,
    String? currencyCode,
  }) async {
    if (name != null) _validate(name);
    await (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(
        name: name != null ? Value(name.trim()) : const Value.absent(),
        type: type != null ? Value(type.value) : const Value.absent(),
        openingBalanceMinor:
            openingBalanceMinor != null
                ? Value(openingBalanceMinor)
                : const Value.absent(),
        currencyCode:
            currencyCode != null
                ? Value(currencyCode.toUpperCase())
                : const Value.absent(),
        updatedAt: Value(nowMs()),
      ),
    );
  }

  Future<void> setArchived(int id, {required bool archived}) async {
    await (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
      AccountsCompanion(isArchived: Value(archived), updatedAt: Value(nowMs())),
    );
  }

  void _validate(String name) {
    if (name.trim().isEmpty) throw ArgumentError('Name is required.');
  }
}
