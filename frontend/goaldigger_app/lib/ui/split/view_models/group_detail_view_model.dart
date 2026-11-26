import 'dart:async';

import '../../../core/result/result.dart';
import '../../../core/utils/parallel.dart';
import '../../../data/models/split.dart';
import '../../../data/repositories/split/split_repository.dart';
import '../../../data/services/realtime/realtime_service.dart';
import '../../core/view_models/auto_refresh_mixin.dart';
import '../../core/view_models/view_model.dart';

typedef _GroupSnapshot = ({
  List<SplitExpense> expenses,
  List<GroupMember> members,
});

/// Expenses and members of a single group.
class GroupDetailViewModel extends ViewModel
    with LoadStateMixin, AutoRefreshMixin {
  GroupDetailViewModel({
    required this.userId,
    required this.group,
    required SplitRepository splitRepository,
    required RealtimeService realtime,
  }) : _splitRepository = splitRepository,
       _realtime = realtime;

  final int userId;
  final GroupSummary group;
  final SplitRepository _splitRepository;
  final RealtimeService _realtime;

  List<SplitExpense> _expenses = const [];
  List<GroupMember> _members = const [];

  List<SplitExpense> get expenses => _expenses;
  List<GroupMember> get members => _members;

  void init() {
    unawaited(load());
    watchRealtime(
      _realtime,
      channelName: 'group-detail-${group.groupId}',
      tables: const [
        'group_members',
        'group_consumptions',
        'consumption_participants',
      ],
      onChange: () => load(silent: true),
    );
  }

  Future<void> load({bool silent = false}) {
    return runLoad<_GroupSnapshot>(
      () async {
        final (expenses, members) = await Parallel.wait2(
          _splitRepository.fetchExpenses(userId),
          _splitRepository.fetchGroupMembers(group.groupId),
        );
        return (
          expenses: expenses.where((e) => e.groupId == group.groupId).toList(),
          members: members,
        );
      },
      (snapshot) {
        _expenses = snapshot.expenses;
        _members = snapshot.members;
      },
      silent: silent,
    );
  }

  SplitExpense? expenseById(int consumptionId) {
    for (final expense in _expenses) {
      if (expense.consumptionId == consumptionId) {
        return expense;
      }
    }
    return null;
  }

  /// Shows a just-saved expense immediately, then reconciles with the server.
  void applySavedExpense(SplitExpenseRequest request) {
    final optimistic = SplitExpense(
      consumptionId:
          request.consumptionId ?? -DateTime.now().microsecondsSinceEpoch,
      groupId: request.groupId,
      groupName: group.groupName,
      name: request.name,
      amount: request.amount,
      createdAt: DateTime.now(),
      participants: [
        for (final share in request.shares)
          SplitParticipant(
            userId: share.userId,
            userName: _memberName(share.userId),
            sharedAmount: share.sharedAmount,
            isPayer: share.userId == request.payerId,
            status: SplitParticipant.statusPending,
          ),
      ],
    );
    _expenses = _upsert(optimistic);
    notifyListeners();
    unawaited(load(silent: true));
  }

  Future<Result<void>> deleteExpense(SplitExpense expense) async {
    final previous = _expenses;
    _expenses = _expenses
        .where((e) => e.consumptionId != expense.consumptionId)
        .toList();
    notifyListeners();

    final result = await guard(
      () => _splitRepository.deleteExpense(expense.consumptionId),
    );
    if (result is Failure) {
      _expenses = previous;
      notifyListeners();
    } else {
      unawaited(load(silent: true));
    }
    return result;
  }

  /// Marks [participant]'s share of [expense] as repaid.
  Future<Result<void>> confirmRepayment(
    SplitExpense expense,
    SplitParticipant participant,
  ) async {
    final result = await guard(
      () => _splitRepository.updateParticipantStatus(
        consumptionId: expense.consumptionId,
        userId: participant.userId,
        status: SplitParticipant.statusPaid,
      ),
    );
    if (result.isSuccess) {
      final current = expenseById(expense.consumptionId) ?? expense;
      _expenses = _upsert(
        current.copyWith(
          participants: [
            for (final p in current.participants)
              p.userId == participant.userId
                  ? p.copyWith(status: SplitParticipant.statusPaid)
                  : p,
          ],
        ),
      );
      notifyListeners();
    }
    return result;
  }

  Future<Result<void>> leaveGroup() {
    return guard(
      () => _splitRepository.leaveGroup(groupId: group.groupId, userId: userId),
    );
  }

  String _memberName(int userId) {
    for (final member in _members) {
      if (member.userId == userId) {
        return member.userName;
      }
    }
    return '成員';
  }

  List<SplitExpense> _upsert(SplitExpense expense) {
    final next = List<SplitExpense>.of(_expenses);
    final index = next.indexWhere(
      (e) => e.consumptionId == expense.consumptionId,
    );
    if (index >= 0) {
      next[index] = expense;
    } else {
      next.insert(0, expense);
    }
    return next;
  }
}
