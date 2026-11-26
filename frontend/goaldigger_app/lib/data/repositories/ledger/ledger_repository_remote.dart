import '../../models/ledger_record.dart';
import '../../services/api/api_client.dart';
import '../../services/data_change_notifier.dart';
import 'ledger_repository.dart';

class LedgerRepositoryRemote implements LedgerRepository {
  LedgerRepositoryRemote(this._api, this._changes);

  final ApiClient _api;
  final DataChangeNotifier _changes;

  @override
  Future<List<LedgerRecord>> fetchHistory(int userId, {int limit = 50}) async {
    final body = await _api.get(
      '/ledger/history/$userId',
      query: {'limit': '$limit'},
    );
    return body.asJsonList.map(LedgerRecord.fromJson).toList();
  }

  @override
  Future<void> create({
    required int userId,
    required LedgerRecordInput input,
  }) async {
    await _api.post('/ledger/', body: _payload(userId, input));
    _changes.notifyDataChanged();
  }

  @override
  Future<void> update({
    required int recordId,
    required int userId,
    required LedgerRecordInput input,
  }) async {
    await _api.put('/ledger/$recordId', body: _payload(userId, input));
    _changes.notifyDataChanged();
  }

  @override
  Future<void> delete(int recordId, {int? goalId}) async {
    await _api.delete(
      '/ledger/$recordId',
      query: goalId == null ? null : {'goal_id': '$goalId'},
    );
    _changes.notifyDataChanged();
  }

  Map<String, dynamic> _payload(int userId, LedgerRecordInput input) => {
    'user_id': userId,
    'type_id': input.typeId,
    'amount': input.amount,
    'description': input.description,
    'goal_id': input.goalId,
  };
}
