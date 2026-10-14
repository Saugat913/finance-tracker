import 'package:flutter/foundation.dart';
import 'package:finance_tracker/features/money/data/model/transaction_type.dart';
import 'package:finance_tracker/features/money/data/repository/transaction_repository.dart';
import 'package:finance_tracker/features/plan/data/repository/goal_repository.dart';
import 'package:finance_tracker/features/shared/data/finance_store.dart';
import 'package:finance_tracker/features/work/data/model/work.dart';
import 'package:finance_tracker/features/work/data/repository/shift_repository.dart';

enum AssistantActionKind { none, addExpense, scheduleShift, moveMoney }

class AssistantActionPending {
  const AssistantActionPending({
    required this.kind,
    required this.title,
    this.amountMinor,
    this.category,
    this.merchant,
    this.jobName,
    this.jobId,
    this.date,
    this.startTime,
    this.endTime,
    this.goalName,
    this.goalId,
    this.fromAccountName,
  });

  final AssistantActionKind kind;
  final String title;
  final int? amountMinor;
  final String? category;
  final String? merchant;
  final String? jobName;
  final int? jobId;
  final DateTime? date;
  final String? startTime;
  final String? endTime;
  final String? goalName;
  final int? goalId;
  final String? fromAccountName;
}

class AssistantMessage {
  AssistantMessage({
    required this.isUser,
    required this.text,
    this.headline,
    this.explanation,
    this.suggestions = const [],
    this.pendingAction,
    this.isConfirmed = false,
    this.confirmedSummary,
  });

  final bool isUser;
  final String text;
  final String? headline;
  final String? explanation;
  final List<String> suggestions;
  AssistantActionPending? pendingAction;
  bool isConfirmed;
  String? confirmedSummary;
}

class AssistantViewModel extends ChangeNotifier {
  AssistantViewModel({
    required this.financeStore,
    required this.transactionRepo,
    required this.shiftRepo,
    required this.goalRepo,
  });

  final FinanceStore financeStore;
  final TransactionRepository transactionRepo;
  final ShiftRepository shiftRepo;
  final GoalRepository goalRepo;

  final List<AssistantMessage> _messages = [];
  List<AssistantMessage> get messages => _messages;

  String get baseCurrency => financeStore.baseCurrency;

  void sendMessage(String query) {
    final text = query.trim();
    if (text.isEmpty) return;

    _messages.add(AssistantMessage(isUser: true, text: text));
    notifyListeners();

    final lower = text.toLowerCase();

    // Check if it's an actionable "Do" command
    if (lower.contains('spent') || lower.contains('woolworths') || lower.contains('add an expense')) {
      _messages.add(
        AssistantMessage(
          isUser: false,
          text: 'I can add this expense. Nothing is saved until you confirm.',
          pendingAction: const AssistantActionPending(
            kind: AssistantActionKind.addExpense,
            title: 'New expense',
            amountMinor: 5420,
            category: 'Groceries',
            merchant: 'Woolworths',
          ),
        ),
      );
    } else if (lower.contains('shift') || lower.contains('café') || lower.contains('schedule a shift')) {
      final job = financeStore.jobs.isNotEmpty ? financeStore.jobs.first : null;
      _messages.add(
        AssistantMessage(
          isUser: false,
          text: 'I can add this shift. Nothing is saved until you confirm.',
          pendingAction: AssistantActionPending(
            kind: AssistantActionKind.scheduleShift,
            title: 'New shift',
            jobName: job?.name ?? 'Café',
            jobId: job?.id ?? 1,
            date: DateTime.now().add(const Duration(days: 2)),
            startTime: '4:00 pm',
            endTime: '10:00 pm',
          ),
        ),
      );
    } else if (lower.contains('emergency fund') || lower.contains('move money') || lower.contains('goal')) {
      final goal = financeStore.goals.isNotEmpty ? financeStore.goals.first : null;
      _messages.add(
        AssistantMessage(
          isUser: false,
          text: 'I can move money into your goal. Nothing changes until you confirm.',
          pendingAction: AssistantActionPending(
            kind: AssistantActionKind.moveMoney,
            title: 'Move money',
            amountMinor: 5000,
            goalName: goal?.name ?? 'Emergency fund',
            goalId: goal?.id ?? 1,
            fromAccountName: financeStore.accounts.isNotEmpty ? financeStore.accounts.first.name : 'Everyday account',
          ),
        ),
      );
    } else {
      // Deterministic analytical answer from engine
      final answer = financeStore.ask(text);
      _messages.add(
        AssistantMessage(
          isUser: false,
          text: answer.body,
          headline: answer.headline,
          explanation: answer.explanation,
          suggestions: answer.suggestions,
        ),
      );
    }

    notifyListeners();
  }

  Future<void> confirmAction(AssistantMessage msg) async {
    final action = msg.pendingAction;
    if (action == null) return;

    if (action.kind == AssistantActionKind.addExpense) {
      final accountId = financeStore.accounts.isNotEmpty ? financeStore.accounts.first.id : 1;
      await transactionRepo.add(
        accountId: accountId,
        amountMinor: action.amountMinor ?? 5420,
        type: TransactionType.expense,
        category: action.category ?? 'Groceries',
        note: action.merchant ?? 'Woolworths',
        occurredAt: DateTime.now(),
      );
      msg.isConfirmed = true;
      msg.confirmedSummary = 'Done. I added it and updated your balance.';
    } else if (action.kind == AssistantActionKind.scheduleShift) {
      final now = DateTime.now();
      await shiftRepo.add(
        jobId: action.jobId ?? 1,
        startAt: DateTime(now.year, now.month, now.day + 2, 16, 0),
        endAt: DateTime(now.year, now.month, now.day + 2, 22, 0),
        status: ShiftStatus.scheduled,
      );
      msg.isConfirmed = true;
      msg.confirmedSummary = 'Done. It is on your calendar.';
    } else if (action.kind == AssistantActionKind.moveMoney) {
      if (action.goalId != null) {
        await goalRepo.addContribution(
          goalId: action.goalId!,
          amountMinor: action.amountMinor ?? 5000,
          note: 'Assistant transfer',
        );
      }
      msg.isConfirmed = true;
      msg.confirmedSummary = 'Done. Transferred to ${action.goalName}.';
    }

    notifyListeners();
  }
}
