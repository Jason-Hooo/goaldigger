import '../../models/ledger_record.dart';

/// Fields submitted when creating or updating a ledger record.
class LedgerRecordInput {
  const LedgerRecordInput({
    required this.typeId,
    required this.amount,
    this.description,
    this.goalId,
  });

  final int typeId;
  final double amount;
  final String? description;
  final int? goalId;
}

abstract interface class LedgerRepository {
  Future<List<LedgerRecord>> fetchHistory(int userId, {int limit = 50});

  Future<void> create({required int userId, required LedgerRecordInput input});

  Future<void> update({
    required int recordId,
    required int userId,
    required LedgerRecordInput input,
  });

  Future<void> delete(int recordId, {int? goalId});
}
