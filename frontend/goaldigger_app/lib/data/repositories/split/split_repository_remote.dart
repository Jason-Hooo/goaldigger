import '../../models/split.dart';
import '../../services/api/api_client.dart';
import '../../services/data_change_notifier.dart';
import 'split_repository.dart';

class SplitRepositoryRemote implements SplitRepository {
  SplitRepositoryRemote(this._api, this._changes);

  final ApiClient _api;
  final DataChangeNotifier _changes;

  @override
  Future<List<GroupSummary>> fetchGroups(int userId) async {
    final body = await _api.get('/splits/groups/$userId');
    return body.asJsonList.map(GroupSummary.fromJson).toList();
  }

  @override
  Future<GroupSummary> createGroup({
    required String groupName,
    required List<int> userIds,
  }) async {
    final body = await _api.post(
      '/splits/groups/',
      body: {'group_name': groupName, 'user_ids': userIds},
    );
    final group = GroupSummary.fromJson(
      body.dataEnvelope('建立群組失敗，未取得回傳資料'),
    );
    _changes.notifyDataChanged();
    return group;
  }

  @override
  Future<void> addGroupMembers({
    required int groupId,
    required List<int> userIds,
  }) async {
    await _api.post(
      '/splits/groups/$groupId/members',
      body: {'user_ids': userIds},
    );
    _changes.notifyDataChanged();
  }

  @override
  Future<void> joinGroupByCode({
    required String invitationCode,
    required int userId,
  }) async {
    await _api.post(
      '/splits/groups/join-by-code',
      body: {'invitation_code': invitationCode, 'user_id': userId},
    );
    _changes.notifyDataChanged();
  }

  @override
  Future<void> leaveGroup({required int groupId, required int userId}) async {
    await _api.delete('/splits/groups/$groupId/members/$userId');
    _changes.notifyDataChanged();
  }

  @override
  Future<List<GroupMember>> fetchGroupMembers(int groupId) async {
    final body = await _api.get('/splits/groups/$groupId/members');
    return body.asJsonList.map(GroupMember.fromJson).toList();
  }

  @override
  Future<List<SplitExpense>> fetchExpenses(int userId) async {
    final body = await _api.get('/splits/expenses/$userId');
    return body.asJsonList.map(SplitExpense.fromJson).toList();
  }

  @override
  Future<void> saveExpense(SplitExpenseRequest request) async {
    final consumptionId = request.consumptionId;
    if (consumptionId == null) {
      await _api.post('/splits/expenses/create', body: request.toJson());
    } else {
      await _api.put('/splits/expenses/$consumptionId', body: request.toJson());
    }
    _changes.notifyDataChanged();
  }

  @override
  Future<void> deleteExpense(int consumptionId) async {
    await _api.delete('/splits/expenses/$consumptionId');
    _changes.notifyDataChanged();
  }

  @override
  Future<void> updateParticipantStatus({
    required int consumptionId,
    required int userId,
    required String status,
  }) async {
    await _api.put(
      '/splits/expenses/$consumptionId/participants/$userId/status',
      query: {'status': status},
    );
    _changes.notifyDataChanged();
  }

  @override
  Future<List<Settlement>> fetchSettlements(int groupId) async {
    final body = await _api.get('/splits/settle/$groupId');
    final json = body.asJsonObject('無法取得結算建議');
    return (json['settlements'] as Object?).asJsonList
        .map(Settlement.fromJson)
        .toList();
  }
}
