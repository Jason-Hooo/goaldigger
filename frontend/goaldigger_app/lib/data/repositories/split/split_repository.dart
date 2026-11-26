import '../../models/split.dart';

abstract interface class SplitRepository {
  Future<List<GroupSummary>> fetchGroups(int userId);

  Future<GroupSummary> createGroup({
    required String groupName,
    required List<int> userIds,
  });

  Future<void> addGroupMembers({
    required int groupId,
    required List<int> userIds,
  });

  Future<void> joinGroupByCode({
    required String invitationCode,
    required int userId,
  });

  Future<void> leaveGroup({required int groupId, required int userId});

  Future<List<GroupMember>> fetchGroupMembers(int groupId);

  /// Every split expense the user participates in, across all groups.
  Future<List<SplitExpense>> fetchExpenses(int userId);

  /// Creates the expense when `request.consumptionId` is null, else updates.
  Future<void> saveExpense(SplitExpenseRequest request);

  Future<void> deleteExpense(int consumptionId);

  Future<void> updateParticipantStatus({
    required int consumptionId,
    required int userId,
    required String status,
  });

  Future<List<Settlement>> fetchSettlements(int groupId);
}
