import 'dart:async';

import '../../../core/result/result.dart';
import '../../../data/models/expense_type.dart';
import '../../../data/repositories/expense_type/expense_type_repository.dart';
import '../../core/view_models/view_model.dart';

/// Manages the user's custom ledger categories.
class SettingsViewModel extends ViewModel with LoadStateMixin {
  SettingsViewModel({
    required this.userId,
    required ExpenseTypeRepository expenseTypeRepository,
  }) : _repository = expenseTypeRepository;

  static const String _loadError = '讀取失敗，請稍後再試。';

  final int userId;
  final ExpenseTypeRepository _repository;

  List<ExpenseType> _types = const [];

  /// Categories owned by the current user.
  List<ExpenseType> get customTypes =>
      _types.where((type) => type.ownerUserId == userId).toList();

  void init() => unawaited(load());

  Future<void> load() {
    return runLoad<List<ExpenseType>>(
      () => _repository.fetchForUser(userId),
      (types) => _types = types,
      fallbackMessage: _loadError,
    );
  }

  Future<Result<void>> create(ExpenseTypeDraft draft) async {
    final tempId = -DateTime.now().microsecondsSinceEpoch;
    _types = [
      ExpenseType(
        id: tempId,
        name: draft.name,
        isExpense: draft.isExpense,
        ownerUserId: userId,
      ),
      ..._types,
    ];
    notifyListeners();

    final result = await guard(
      () => _repository.create(userId: userId, draft: draft),
      fallbackMessage: _loadError,
    );
    _types = switch (result) {
      Success(value: final created) => _replace(tempId, created),
      Failure() => _types.where((t) => t.id != tempId).toList(),
    };
    notifyListeners();
    return result;
  }

  Future<Result<void>> update(ExpenseType type, ExpenseTypeDraft draft) async {
    final previous = _types;
    _types = _replace(
      type.id,
      type.copyWith(name: draft.name, isExpense: draft.isExpense),
    );
    notifyListeners();

    final result = await guard(
      () => _repository.update(typeId: type.id, userId: userId, draft: draft),
      fallbackMessage: _loadError,
    );
    _types = switch (result) {
      Success(value: final updated) => _replace(updated.id, updated),
      Failure() => previous,
    };
    notifyListeners();
    return result;
  }

  Future<Result<void>> delete(ExpenseType type) async {
    final previous = _types;
    _types = _types.where((t) => t.id != type.id).toList();
    notifyListeners();

    final result = await guard(
      () => _repository.delete(typeId: type.id, userId: userId),
      fallbackMessage: _loadError,
    );
    if (result is Failure) {
      _types = previous;
      notifyListeners();
    }
    return result;
  }

  List<ExpenseType> _replace(int id, ExpenseType replacement) => [
    for (final type in _types) type.id == id ? replacement : type,
  ];
}
