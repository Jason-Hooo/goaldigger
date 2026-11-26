import '../../models/expense_type.dart';
import '../../services/api/api_client.dart';
import '../../services/data_change_notifier.dart';
import 'expense_type_repository.dart';

class ExpenseTypeRepositoryRemote implements ExpenseTypeRepository {
  ExpenseTypeRepositoryRemote(this._api, this._changes);

  final ApiClient _api;
  final DataChangeNotifier _changes;

  @override
  Future<List<ExpenseType>> fetchForUser(int userId) async {
    final body = await _api.get('/ledger/types', query: {'user_id': '$userId'});
    return body.asJsonList.map(ExpenseType.fromJson).toList();
  }

  @override
  Future<List<ExpenseType>> fetchAll() async {
    final body = await _api.get('/ledger/types');
    return body.asJsonList.map(ExpenseType.fromJson).toList();
  }

  @override
  Future<ExpenseType> create({
    required int userId,
    required ExpenseTypeDraft draft,
  }) async {
    final body = await _api.post('/ledger/types', body: _payload(userId, draft));
    final created = ExpenseType.fromJson(
      body.dataEnvelope('新增類別失敗，未取得回傳資料'),
    );
    _changes.notifyDataChanged();
    return created;
  }

  @override
  Future<ExpenseType> update({
    required int typeId,
    required int userId,
    required ExpenseTypeDraft draft,
  }) async {
    final body = await _api.put(
      '/ledger/types/$typeId',
      body: _payload(userId, draft),
    );
    final updated = ExpenseType.fromJson(
      body.dataEnvelope('更新類別失敗，未取得回傳資料'),
    );
    _changes.notifyDataChanged();
    return updated;
  }

  @override
  Future<void> delete({required int typeId, required int userId}) async {
    await _api.delete('/ledger/types/$typeId', query: {'user_id': '$userId'});
    _changes.notifyDataChanged();
  }

  Map<String, dynamic> _payload(int userId, ExpenseTypeDraft draft) => {
    'user_id': userId,
    'type_name': draft.name,
    'is_expense': draft.isExpense,
  };
}
