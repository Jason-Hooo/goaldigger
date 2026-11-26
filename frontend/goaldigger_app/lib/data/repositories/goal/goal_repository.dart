import '../../models/goal.dart';

abstract interface class GoalRepository {
  Future<List<Goal>> fetchGoals(int userId);

  /// Creates [goal] (its `goalId` is ignored) and returns the stored goal.
  Future<Goal> createGoal({required int userId, required Goal goal});

  /// Partially updates a goal; `null` fields are left unchanged.
  Future<Goal> updateGoal({
    required int goalId,
    String? title,
    String? description,
    double? targetAmount,
    DateTime? deadline,
    double? savedAmount,
  });

  Future<void> deleteGoal(int goalId);

  Future<void> achieveGoal(int goalId);
}
