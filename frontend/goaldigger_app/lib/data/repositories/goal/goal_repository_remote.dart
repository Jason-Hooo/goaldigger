import '../../../core/utils/formatters.dart';
import '../../models/goal.dart';
import '../../services/api/api_client.dart';
import '../../services/data_change_notifier.dart';
import 'goal_repository.dart';

class GoalRepositoryRemote implements GoalRepository {
  GoalRepositoryRemote(this._api, this._changes);

  final ApiClient _api;
  final DataChangeNotifier _changes;

  @override
  Future<List<Goal>> fetchGoals(int userId) async {
    final body = await _api.get('/goals/$userId');
    return body.asJsonList.map(Goal.fromJson).toList();
  }

  @override
  Future<Goal> createGoal({required int userId, required Goal goal}) async {
    final body = await _api.post(
      '/goals/',
      body: {
        'user_id': userId,
        'goal_name': goal.title,
        'description': goal.description,
        'target_amount': goal.targetAmount,
        'deadline': Formatters.isoDate(goal.deadline),
      },
    );
    final created = Goal.fromJson(
      body.asJsonObject('新增目標失敗，未取得回傳資料'),
      fallback: goal.copyWith(savedAmount: 0),
    );
    _changes.notifyDataChanged();
    return created;
  }

  @override
  Future<Goal> updateGoal({
    required int goalId,
    String? title,
    String? description,
    double? targetAmount,
    DateTime? deadline,
    double? savedAmount,
  }) async {
    final body = await _api.put(
      '/goals/$goalId',
      body: {
        'goal_name': title,
        'description': description,
        'target_amount': targetAmount,
        'deadline': deadline == null ? null : Formatters.isoDate(deadline),
        'cumulative_amount': savedAmount,
      },
    );
    final updated = Goal.fromJson(
      body.asJsonObject('更新目標失敗，未取得回傳資料'),
      fallback: Goal(
        goalId: goalId,
        title: title ?? '未命名目標',
        description: description ?? '',
        targetAmount: targetAmount ?? 0,
        deadline: deadline ?? DateTime.now(),
        savedAmount: savedAmount ?? 0,
      ),
    );
    _changes.notifyDataChanged();
    return updated;
  }

  @override
  Future<void> deleteGoal(int goalId) async {
    await _api.delete('/goals/$goalId');
    _changes.notifyDataChanged();
  }

  @override
  Future<void> achieveGoal(int goalId) async {
    await _api.post('/goals/achieve/$goalId');
    _changes.notifyDataChanged();
  }
}
