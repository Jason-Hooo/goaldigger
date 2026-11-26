import 'package:flutter_test/flutter_test.dart';
import 'package:goaldigger_app/core/errors/app_exception.dart';
import 'package:goaldigger_app/core/result/result.dart';
import 'package:goaldigger_app/data/models/goal.dart';
import 'package:goaldigger_app/data/services/data_change_notifier.dart';
import 'package:goaldigger_app/ui/goals/view_models/goals_view_model.dart';

import '../helpers/fakes.dart';

void main() {
  final deadline = DateTime.now().add(const Duration(days: 30));
  Goal goal(int id, {double saved = 0, String? status}) => Goal(
    goalId: id,
    title: 'Goal $id',
    description: '',
    targetAmount: 100,
    deadline: deadline,
    savedAmount: saved,
    status: status,
  );

  late FakeGoalRepository repository;
  late DataChangeNotifier changes;
  late GoalsViewModel viewModel;

  setUp(() {
    repository = FakeGoalRepository([
      goal(1, saved: 50),
      goal(2, saved: 100),
      goal(3, saved: 100, status: Goal.statusAchieved),
    ]);
    changes = DataChangeNotifier();
    viewModel = GoalsViewModel(
      userId: 1,
      goalRepository: repository,
      dataChanges: changes,
    );
  });

  tearDown(() => viewModel.dispose());

  test('summarises only current goals', () async {
    await viewModel.load();

    expect(viewModel.currentGoals.map((g) => g.goalId), [1, 2]);
    expect(viewModel.achievedGoals.map((g) => g.goalId), [3]);
    expect(viewModel.totalSaved, 150);
    expect(viewModel.totalTarget, 200);
    expect(viewModel.overallProgress, closeTo(0.75, 1e-9));
  });

  test('load failure exposes the error message', () async {
    repository.fetchError = const AppException('offline');

    await viewModel.load();

    expect(viewModel.errorMessage, 'offline');
    expect(viewModel.isLoading, isFalse);
  });

  test('reloads silently when data changes elsewhere', () async {
    viewModel.init();
    await pump();
    repository.goals = [goal(9)];

    changes.notifyDataChanged();
    await pump();

    expect(viewModel.goals.single.goalId, 9);
  });

  test('achieve marks goal achieved optimistically', () async {
    await viewModel.load();

    final result = await viewModel.achieve(viewModel.goals[1]);

    expect(result, isA<Success<void>>());
    expect(repository.achieved, [2]);
    expect(viewModel.achievedGoals.map((g) => g.goalId), contains(2));
  });

  test('failed delete rolls back', () async {
    await viewModel.load();
    repository.shouldFail = true;

    final result = await viewModel.delete(viewModel.goals.first);

    expect(result, isA<Failure<void>>());
    expect(viewModel.goals, hasLength(3));
  });

  test('adjustment never goes below zero', () async {
    await viewModel.load();

    await viewModel.adjustSavedAmount(viewModel.goals.first, -500);

    expect(viewModel.goals.first.savedAmount, 0);
    expect(repository.updates.single.savedAmount, 0);
  });

  test('create replaces the temporary goal with the stored one', () async {
    await viewModel.load();

    await viewModel.save(
      Goal(
        title: 'New',
        description: 'd',
        targetAmount: 10,
        deadline: deadline,
        savedAmount: 5,
      ),
      isNew: true,
    );

    final created = viewModel.goals.first;
    expect(created.goalId, 100);
    expect(created.savedAmount, 5);
    expect(viewModel.goals.where((g) => (g.goalId ?? 0) < 0), isEmpty);
  });

  test('validateAdjustment', () {
    final g = goal(1, saved: 40);
    expect(GoalsViewModel.validateAdjustment(g, 70, increase: true), isNotNull);
    expect(GoalsViewModel.validateAdjustment(g, 60, increase: true), isNull);
    expect(
      GoalsViewModel.validateAdjustment(g, 41, increase: false),
      isNotNull,
    );
  });
}
