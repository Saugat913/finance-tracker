import 'package:finance_tracker/features/money/data/model/transaction_type.dart';

class TransactionCategory {
  const TransactionCategory(this.value, this.label, this.type);

  final String value;
  final String label;
  final TransactionType type;
}

/// Built-in categories. Keep values stable for database persistence.
abstract final class TransactionCategories {
  static const all = <TransactionCategory>[
    TransactionCategory('salary', 'Salary', TransactionType.income),
    TransactionCategory('shift_pay', 'Shift pay', TransactionType.income),
    TransactionCategory('business', 'Business', TransactionType.income),
    TransactionCategory('interest', 'Interest', TransactionType.income),
    TransactionCategory('gift_received', 'Gift received', TransactionType.income),
    TransactionCategory('other_income', 'Other income', TransactionType.income),
    TransactionCategory('groceries', 'Groceries', TransactionType.expense),
    TransactionCategory('eating_out', 'Eating out', TransactionType.expense),
    TransactionCategory(
      'entertainment',
      'Entertainment',
      TransactionType.expense,
    ),
    TransactionCategory('transport', 'Transport', TransactionType.expense),
    TransactionCategory('bills', 'Bills', TransactionType.expense),
    TransactionCategory(
      'other_expense',
      'Other expense',
      TransactionType.expense,
    ),
  ];

  /// Suggested merchants per category value, offered as quick-fill chips.
  static const suggestedMerchants = <String, List<String>>{
    'groceries': ['Woolworths', 'Coles', 'Aldi'],
    'eating_out': ["Domino's", 'KFC', "McDonald's", 'Uber Eats'],
    'entertainment': ['Netflix', 'Spotify', 'QFX', 'Prime Video'],
    'transport': ['Opal', 'Uber', 'Shell'],
    'bills': ['Rent', 'Electricity', 'Internet', 'Phone'],
  };

  static List<String> merchantsFor(String categoryOrKey) {
    final needle = categoryOrKey.trim().toLowerCase();
    final cat = find(needle, TransactionType.expense) ??
        find(needle, TransactionType.income);
    final key = cat?.value ?? needle;
    return suggestedMerchants[key] ?? const [];
  }

  static List<TransactionCategory> forType(TransactionType type) =>
      all.where((category) => category.type == type).toList(growable: false);

  static TransactionCategory? find(String valueOrLabel, TransactionType type) {
    final needle = valueOrLabel.trim().toLowerCase();
    for (final category in all) {
      if (category.type == type &&
          (category.value.toLowerCase() == needle ||
              category.label.toLowerCase() == needle)) {
        return category;
      }
    }
    return null;
  }

  static TransactionCategory fromValue(String valueOrLabel, TransactionType type) =>
      find(valueOrLabel, type) ??
      all.firstWhere(
        (category) => category.type == type,
        orElse: () => all.first,
      );
}
