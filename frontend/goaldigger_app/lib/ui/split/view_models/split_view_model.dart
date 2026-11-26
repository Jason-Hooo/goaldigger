import 'dart:async';

import '../../../core/result/result.dart';
import '../../../core/utils/parallel.dart';
import '../../../data/models/split.dart';
import '../../../data/repositories/split/split_repository.dart';
import '../../../data/services/data_change_notifier.dart';
import '../../core/view_models/auto_refresh_mixin.dart';
import '../../core/view_models/view_model.dart';

typedef _SplitSnapshot = ({
  List<GroupSummary> groups,
  List<SplitExpense> expenses,
});

/// Overview of the user's groups and outstanding split balances.
class SplitViewModel extends ViewModel with LoadStateMixin, AutoRefreshMixin {
  SplitViewModel({
    required this.userId,
    required SplitRepository splitRepository,
    required DataChangeNotifier dataChanges,
  }) : _splitRepository = splitRepository,
       _dataChanges = dataChanges;

  final int userId;
  final SplitRepository _splitRepository;
  final DataChangeNotifier _dataChanges;

  List<GroupSummary> _groups = const [];
  List<SplitExpense> _expenses = const [];

  List<GroupSummary> get groups => _groups;

  int get groupCount => _groups.map((group) => group.groupName).toSet().length;

  /// Total the user still owes to others.
  double get payableTotal => _expenses.fold<double>(
    0,
    (sum, expense) => sum + expense.balanceFor(userId).payable,
  );

  /// Total others still owe the user.
  double get receivableTotal => _expenses.fold<double>(
    0,
    (sum, expense) => sum + expense.balanceFor(userId).receivable,
  );

  void init() {
    unawaited(load());
    listenToDataChanges(_dataChanges, () => load(silent: true));
  }

  Future<void> load({bool silent = false}) {
    return runLoad<_SplitSnapshot>(
      () async {
        final (groups, expenses) = await Parallel.wait2(
          _splitRepository.fetchGroups(userId),
          _splitRepository.fetchExpenses(userId),
        );
        return (groups: groups, expenses: expenses);
      },
      (snapshot) {
        _groups = snapshot.groups;
        _expenses = snapshot.expenses;
      },
      silent: silent,
    );
  }

  Future<Result<GroupSummary>> createGroup(String groupName) async {
    final result = await guard(
      () => _splitRepository.createGroup(
        groupName: groupName,
        userIds: [userId],
      ),
    );
    if (result case Success(value: final group)) {
      _groups = [
        group,
        ..._groups.where((g) => g.groupId != group.groupId),
      ];
      notifyListeners();
    }
    return result;
  }

  Future<Result<void>> joinGroup(String invitationCode) async {
    final result = await guard(
      () => _splitRepository.joinGroupByCode(
        invitationCode: invitationCode.trim().toUpperCase(),
        userId: userId,
      ),
    );
    if (result.isSuccess) {
      await load(silent: true);
    }
    return result;
  }
}
