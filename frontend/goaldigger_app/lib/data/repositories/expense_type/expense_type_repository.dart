import '../../models/expense_type.dart';

abstract interface class ExpenseTypeRepository {
  /// Predefined categories plus the custom categories owned by [userId].
  Future<List<ExpenseType>> fetchForUser(int userId);

  /// All categories without user scoping.
  Future<List<ExpenseType>> fetchAll();

  Future<ExpenseType> create({
    required int userId,
    required ExpenseTypeDraft draft,
  });

  Future<ExpenseType> update({
    required int typeId,
    required int userId,
    required ExpenseTypeDraft draft,
  });

  Future<void> delete({required int typeId, required int userId});
}
