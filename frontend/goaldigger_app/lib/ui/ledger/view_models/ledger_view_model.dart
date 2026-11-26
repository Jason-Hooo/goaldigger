import 'dart:async';

import '../../../core/result/result.dart';
import '../../../core/utils/parallel.dart';
import '../../../data/models/expense_type.dart';
import '../../../data/models/goal.dart';
import '../../../data/models/ledger_record.dart';
import '../../../data/repositories/expense_type/expense_type_repository.dart';
import '../../../data/repositories/goal/goal_repository.dart';
import '../../../data/repositories/ledger/ledger_repository.dart';
import '../../../data/services/data_change_notifier.dart';
import '../../../data/services/realtime/realtime_service.dart';
import '../../core/view_models/auto_refresh_mixin.dart';
import '../../core/view_models/view_model.dart';
import 'ledger_entry.dart';

typedef _LedgerSnapshot = ({
  List<ExpenseType> types,
  List<Goal> goals,
  List<LedgerRecord> records,
});

class LedgerViewModel extends ViewModel with LoadStateMixin, AutoRefreshMixin {
  LedgerViewModel({
    required this.userId,
    required LedgerRepository ledgerRepository,
    required ExpenseTypeRepository expenseTypeRepository,
    required GoalRepository goalRepository,
    required DataChangeNotifier dataChanges,
    required RealtimeService realtime,
  }) : _ledgerRepository = ledgerRepository,
       _expenseTypeRepository = expenseTypeRepository,
       _goalRepository = goalRepository,
       _dataChanges = dataChanges,
       _realtime = realtime;

  static const int historyLimit = 80;

  final int userId;
  final LedgerRepository _ledgerRepository;
  final ExpenseTypeRepository _expenseTypeRepository;
  final GoalRepository _goalRepository;
  final DataChangeNotifier _dataChanges;
  final RealtimeService _realtime;

  List<LedgerEntry> _entries = const [];
  List<ExpenseType> _expenseTypes = const [];
  List<Goal> _goals = const [];

  List<LedgerEntry> get entries => _entries;
  List<ExpenseType> get expenseTypes => _expenseTypes;
  List<Goal> get goals => _goals;

  bool get canCreateEntry => _expenseTypes.isNotEmpty;

  double get incomeTotal => _sum(income: true);
  double get expenseTotal => _sum(income: false);
  double get balance => incomeTotal - expenseTotal;

  void init() {
    unawaited(load());
    listenToDataChanges(_dataChanges, () => load(silent: true));
    watchRealtime(
      _realtime,
      channelName: 'ledger-$userId',
      tables: const [
        'personal_consumptions',
        'expense_types',
        'group_consumptions',
        'consumption_participants',
      ],
      onChange: () => load(silent: true),
    );
  }

  Future<void> load({bool silent = false}) {
    return runLoad<_LedgerSnapshot>(
      () async {
        final (types, goals, records) = await Parallel.wait3(
          _expenseTypeRepository.fetchForUser(userId),
          _goalRepository.fetchGoals(userId),
          _ledgerRepository.fetchHistory(userId, limit: historyLimit),
        );
        return (types: types, goals: goals, records: records);
      },
      (snapshot) {
        _expenseTypes = snapshot.types;
        _goals = snapshot.goals;
        _entries = snapshot.records.map(_toEntry).toList();
      },
      silent: silent,
    );
  }

  /// Optimistically applies [draft], then persists it. Rolls back on failure.
  Future<Result<void>> save(LedgerDraft draft) async {
    final previous = _entries;
    final existing = draft.isNew ? null : _findEntry(draft.recordId!);
    final optimistic = _toEntry(
      LedgerRecord(
        recordId: draft.recordId ?? -DateTime.now().microsecondsSinceEpoch,
        typeId: draft.typeId,
        amount: draft.amount,
        createdAt: existing?.recordedAt ?? DateTime.now(),
        description: LedgerRecord.encodeDescription(
          title: draft.title,
          note: draft.note,
        ),
        isExpense: !draft.isIncome,
        goalId: draft.goalId,
      ),
    );
    _entries = _upsert(_entries, optimistic);
    notifyListeners();

    final input = LedgerRecordInput(
      typeId: draft.typeId,
      amount: draft.amount,
      description: LedgerRecord.encodeDescription(
        title: draft.title,
        note: draft.note,
      ),
      goalId: draft.goalId,
    );
    final result = await guard(
      () => draft.isNew
          ? _ledgerRepository.create(userId: userId, input: input)
          : _ledgerRepository.update(
              recordId: draft.recordId!,
              userId: userId,
              input: input,
            ),
    );
    if (result is Failure) {
      _entries = previous;
      notifyListeners();
    }
    return result;
  }

  /// Deletes [entry] unless it is linked to an already achieved goal.
  Future<Result<void>> delete(LedgerEntry entry) async {
    final linkedGoalId = entry.goalId;
    if (linkedGoalId != null &&
        _goals.any((goal) => goal.goalId == linkedGoalId && goal.isAchieved)) {
      return const Result.failure('此帳目已同步至已達成的目標，無法刪除。');
    }

    final previous = _entries;
    _entries = _entries.where((e) => e.recordId != entry.recordId).toList();
    notifyListeners();

    final result = await guard(
      () => _ledgerRepository.delete(entry.recordId, goalId: entry.goalId),
    );
    if (result is Failure) {
      _entries = previous;
      notifyListeners();
    }
    return result;
  }

  LedgerEntry _toEntry(LedgerRecord record) {
    ExpenseType? type;
    for (final candidate in _expenseTypes) {
      if (candidate.id == record.typeId) {
        type = candidate;
        break;
      }
    }
    final categoryName = record.typeName ?? type?.name ?? '未分類';
    final isExpense = record.isExpense ?? type?.isExpense ?? true;
    return LedgerEntry(
      recordId: record.recordId,
      typeId: record.typeId,
      goalId: record.goalId,
      title: record.titleOr(categoryName),
      note: record.note,
      categoryName: categoryName,
      amount: record.amount,
      isIncome: !isExpense,
      recordedAt: record.createdAt,
    );
  }

  LedgerEntry? _findEntry(int recordId) {
    for (final entry in _entries) {
      if (entry.recordId == recordId) {
        return entry;
      }
    }
    return null;
  }

  List<LedgerEntry> _upsert(List<LedgerEntry> entries, LedgerEntry entry) {
    final next = List<LedgerEntry>.of(entries);
    final index = next.indexWhere((e) => e.recordId == entry.recordId);
    if (index >= 0) {
      next[index] = entry;
    } else {
      next.insert(0, entry);
    }
    return next;
  }

  double _sum({required bool income}) => _entries
      .where((entry) => entry.isIncome == income)
      .fold<double>(0, (sum, entry) => sum + entry.amount);
}
