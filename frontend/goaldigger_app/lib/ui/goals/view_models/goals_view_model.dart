import 'dart:async';

import '../../../core/result/result.dart';
import '../../../data/models/goal.dart';
import '../../../data/repositories/goal/goal_repository.dart';
import '../../../data/services/data_change_notifier.dart';
import '../../core/view_models/auto_refresh_mixin.dart';
import '../../core/view_models/view_model.dart';

class GoalsViewModel extends ViewModel with LoadStateMixin, AutoRefreshMixin {
  GoalsViewModel({
    required this.userId,
    required GoalRepository goalRepository,
    required DataChangeNotifier dataChanges,
  }) : _goalRepository = goalRepository,
       _dataChanges = dataChanges;

  final int userId;
  final GoalRepository _goalRepository;
  final DataChangeNotifier _dataChanges;

  List<Goal> _goals = const [];

  List<Goal> get goals => _goals;

  List<Goal> get currentGoals =>
      _goals.where((goal) => !goal.isAchieved).toList();

  List<Goal> get achievedGoals =>
      _goals.where((goal) => goal.isAchieved).toList();

  double get totalTarget =>
      currentGoals.fold<double>(0, (sum, goal) => sum + goal.targetAmount);

  double get totalSaved =>
      currentGoals.fold<double>(0, (sum, goal) => sum + goal.savedAmount);

  /// Mean progress across current (not yet achieved) goals.
  double get overallProgress {
    final current = currentGoals;
    if (current.isEmpty) {
      return 0;
    }
    final total = current.fold<double>(0, (sum, goal) => sum + goal.progress);
    return total / current.length;
  }

  void init() {
    unawaited(load());
    listenToDataChanges(_dataChanges, () => load(silent: true));
  }

  Future<void> load({bool silent = false}) {
    return runLoad<List<Goal>>(
      () => _goalRepository.fetchGoals(userId),
      (goals) => _goals = goals,
      silent: silent,
    );
  }

  /// Creates [goal] when [isNew], otherwise updates it.
  Future<Result<void>> save(Goal goal, {required bool isNew}) {
    return isNew ? _create(goal) : _update(goal);
  }

  Future<Result<void>> _create(Goal goal) async {
    final tempId = -DateTime.now().microsecondsSinceEpoch;
    _goals = [goal.copyWith(goalId: tempId), ..._goals];
    notifyListeners();

    final result = await guard(() async {
      var created = await _goalRepository.createGoal(userId: userId, goal: goal);
      final createdId = created.goalId;
      if (goal.savedAmount > 0 && createdId != null) {
        await _goalRepository.updateGoal(
          goalId: createdId,
          savedAmount: goal.savedAmount,
        );
        created = created.copyWith(savedAmount: goal.savedAmount);
      }
      return created;
    });

    switch (result) {
      case Success(value: final created):
        _replace(tempId, created);
      case Failure():
        _goals = _goals.where((g) => g.goalId != tempId).toList();
    }
    notifyListeners();
    return result;
  }

  Future<Result<void>> _update(Goal goal) async {
    final goalId = goal.goalId;
    if (goalId == null) {
      return const Result.failure('缺少目標編號，無法更新。');
    }
    return _optimistic(
      (goals) => _mapGoal(goals, goalId, (_) => goal),
      () async {
        final updated = await _goalRepository.updateGoal(
          goalId: goalId,
          title: goal.title,
          description: goal.description,
          targetAmount: goal.targetAmount,
          deadline: goal.deadline,
          savedAmount: goal.savedAmount,
        );
        _replace(goalId, updated);
      },
    );
  }

  Future<Result<void>> delete(Goal goal) {
    final goalId = goal.goalId;
    if (goalId == null) {
      return Future.value(const Result.failure('缺少目標編號，無法刪除。'));
    }
    return _optimistic(
      (goals) => goals.where((g) => g.goalId != goalId).toList(),
      () => _goalRepository.deleteGoal(goalId),
    );
  }

  /// Adds [delta] (may be negative) to the goal's saved amount.
  Future<Result<void>> adjustSavedAmount(Goal goal, double delta) {
    final goalId = goal.goalId;
    if (goalId == null) {
      return Future.value(const Result.failure('缺少目標編號，無法調整。'));
    }
    final raw = goal.savedAmount + delta;
    final savedAmount = raw < 0 ? 0.0 : raw;
    return _optimistic(
      (goals) => _mapGoal(
        goals,
        goalId,
        (g) => g.copyWith(savedAmount: savedAmount),
      ),
      () => _goalRepository.updateGoal(
        goalId: goalId,
        savedAmount: savedAmount,
      ),
    );
  }

  Future<Result<void>> achieve(Goal goal) {
    final goalId = goal.goalId;
    if (goalId == null) {
      return Future.value(const Result.failure('缺少目標編號，無法解鎖成就。'));
    }
    return _optimistic(
      (goals) => _mapGoal(
        goals,
        goalId,
        (g) => g.copyWith(
          achievedAt: DateTime.now(),
          status: Goal.statusAchieved,
        ),
      ),
      () => _goalRepository.achieveGoal(goalId),
    );
  }

  /// Validates a manual progress adjustment; returns an error or `null`.
  static String? validateAdjustment(
    Goal goal,
    double amount, {
    required bool increase,
  }) {
    if (increase) {
      final remaining = goal.remainingAmount;
      if (remaining > 0 && amount > remaining) {
        return '增加金額不可大於剩餘金額。';
      }
    } else if (amount > goal.savedAmount) {
      return '減少金額不可大於目前已存。';
    }
    return null;
  }

  Future<Result<void>> _optimistic(
    List<Goal> Function(List<Goal> goals) apply,
    Future<void> Function() persist,
  ) async {
    final previous = _goals;
    _goals = apply(_goals);
    notifyListeners();

    final result = await guard(persist);
    if (result is Failure) {
      _goals = previous;
      notifyListeners();
    }
    return result;
  }

  void _replace(int goalId, Goal replacement) {
    _goals = _mapGoal(_goals, goalId, (_) => replacement);
    notifyListeners();
  }

  List<Goal> _mapGoal(List<Goal> goals, int goalId, Goal Function(Goal) f) {
    return [
      for (final goal in goals) goal.goalId == goalId ? f(goal) : goal,
    ];
  }
}
