/// Account types.
enum AccountType {
  cash('cash', 'Cash'),
  bank('bank', 'Bank account'),
  wallet('wallet', 'Wallet'),
  savings('savings', 'Savings');

  const AccountType(this.value, this.label);

  final String value;
  final String label;

  static AccountType fromValue(String value) => AccountType.values.firstWhere(
    (type) => type.value == value,
    orElse: () => AccountType.bank,
  );
}
