import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:goaldigger_app/core/errors/app_exception.dart';
import 'package:goaldigger_app/data/models/auth_user.dart';
import 'package:goaldigger_app/data/models/expense_type.dart';
import 'package:goaldigger_app/data/models/goal.dart';
import 'package:goaldigger_app/data/models/ledger_record.dart';
import 'package:goaldigger_app/data/models/split.dart';
import 'package:goaldigger_app/data/repositories/auth/auth_repository.dart';
import 'package:goaldigger_app/data/repositories/expense_type/expense_type_repository.dart';
import 'package:goaldigger_app/data/repositories/goal/goal_repository.dart';
import 'package:goaldigger_app/data/repositories/ledger/ledger_repository.dart';
import 'package:goaldigger_app/data/repositories/split/split_repository.dart';
import 'package:goaldigger_app/data/services/realtime/realtime_service.dart';

/// Exception the fakes throw when told to fail.
const fakeFailure = AppException('boom');

class FakeRealtimeService implements RealtimeService {
  final Map<String, VoidCallback> listeners = {};
  final List<String> cancelled = [];

  @override
  RealtimeSubscription watchTables({
    required String channelName,
    required List<String> tables,
    required VoidCallback onChange,
  }) {
    listeners[channelName] = onChange;
    return _FakeSubscription(() {
      listeners.remove(channelName);
      cancelled.add(channelName);
    });
  }

  void emit(String channelName) => listeners[channelName]?.call();
}

class _FakeSubscription implements RealtimeSubscription {
  _FakeSubscription(this._onCancel);

  final VoidCallback _onCancel;

  @override
  Future<void> cancel() async => _onCancel();
}

class FakeAuthRepository implements AuthRepository {
  AuthUser user = const AuthUser(userId: 1, name: 'Amy', email: 'a@b.co');
  bool shouldFail = false;
  int loginCalls = 0;
  String? lastPassword;

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    lastPassword = password;
    if (shouldFail) {
      throw const AppException('帳號或密碼錯誤');
    }
    return user;
  }

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (shouldFail) {
      throw fakeFailure;
    }
    return AuthUser(userId: 2, name: name, email: email);
  }

  @override
  Future<void> deleteAccount({
    required int userId,
    required String password,
  }) async {}
}

class FakeExpenseTypeRepository implements ExpenseTypeRepository {
  FakeExpenseTypeRepository([List<ExpenseType>? types])
    : types = types ?? defaultTypes;

  static const defaultTypes = [
    ExpenseType(id: 1, name: '餐飲', isExpense: true),
    ExpenseType(id: 2, name: '薪資', isExpense: false),
    ExpenseType(id: 3, name: '外送', isExpense: true, ownerUserId: 1),
  ];

  List<ExpenseType> types;
  bool shouldFail = false;

  @override
  Future<List<ExpenseType>> fetchForUser(int userId) async => types;

  @override
  Future<List<ExpenseType>> fetchAll() async => types;

  @override
  Future<ExpenseType> create({
    required int userId,
    required ExpenseTypeDraft draft,
  }) async {
    if (shouldFail) {
      throw fakeFailure;
    }
    return ExpenseType(
      id: 99,
      name: draft.name,
      isExpense: draft.isExpense,
      ownerUserId: userId,
    );
  }

  @override
  Future<ExpenseType> update({
    required int typeId,
    required int userId,
    required ExpenseTypeDraft draft,
  }) async {
    if (shouldFail) {
      throw fakeFailure;
    }
    return ExpenseType(
      id: typeId,
      name: draft.name,
      isExpense: draft.isExpense,
      ownerUserId: userId,
    );
  }

  @override
  Future<void> delete({required int typeId, required int userId}) async {
    if (shouldFail) {
      throw fakeFailure;
    }
  }
}

class FakeLedgerRepository implements LedgerRepository {
  FakeLedgerRepository([List<LedgerRecord>? records])
    : records = records ?? [];

  List<LedgerRecord> records;
  bool shouldFail = false;
  int fetchCalls = 0;
  final List<LedgerRecordInput> created = [];
  final List<int> deleted = [];

  /// When set, mutations wait for this to complete (to inspect optimistic
  /// state mid-flight).
  Completer<void>? gate;

  @override
  Future<List<LedgerRecord>> fetchHistory(int userId, {int limit = 50}) async {
    fetchCalls++;
    return records;
  }

  @override
  Future<void> create({
    required int userId,
    required LedgerRecordInput input,
  }) async {
    await gate?.future;
    if (shouldFail) {
      throw fakeFailure;
    }
    created.add(input);
  }

  @override
  Future<void> update({
    required int recordId,
    required int userId,
    required LedgerRecordInput input,
  }) async {
    await gate?.future;
    if (shouldFail) {
      throw fakeFailure;
    }
  }

  @override
  Future<void> delete(int recordId, {int? goalId}) async {
    await gate?.future;
    if (shouldFail) {
      throw fakeFailure;
    }
    deleted.add(recordId);
  }
}

class FakeGoalRepository implements GoalRepository {
  FakeGoalRepository([List<Goal>? goals]) : goals = goals ?? [];

  List<Goal> goals;
  bool shouldFail = false;
  Object? fetchError;
  int nextId = 100;
  final List<int> achieved = [];
  final List<({int goalId, double? savedAmount})> updates = [];

  @override
  Future<List<Goal>> fetchGoals(int userId) async {
    final error = fetchError;
    if (error != null) {
      throw error;
    }
    return goals;
  }

  @override
  Future<Goal> createGoal({required int userId, required Goal goal}) async {
    if (shouldFail) {
      throw fakeFailure;
    }
    return goal.copyWith(goalId: nextId++, savedAmount: 0);
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
    if (shouldFail) {
      throw fakeFailure;
    }
    updates.add((goalId: goalId, savedAmount: savedAmount));
    final existing = goals.firstWhere(
      (g) => g.goalId == goalId,
      orElse: () => Goal(
        goalId: goalId,
        title: title ?? '',
        description: description ?? '',
        targetAmount: targetAmount ?? 0,
        deadline: deadline ?? DateTime(2030),
      ),
    );
    return existing.copyWith(
      title: title,
      description: description,
      targetAmount: targetAmount,
      deadline: deadline,
      savedAmount: savedAmount,
    );
  }

  @override
  Future<void> deleteGoal(int goalId) async {
    if (shouldFail) {
      throw fakeFailure;
    }
  }

  @override
  Future<void> achieveGoal(int goalId) async {
    if (shouldFail) {
      throw fakeFailure;
    }
    achieved.add(goalId);
  }
}

class FakeSplitRepository implements SplitRepository {
  List<GroupSummary> groups = [];
  List<SplitExpense> expenses = [];
  List<GroupMember> members = [];
  List<Settlement> settlements = [];
  bool shouldFail = false;
  final List<SplitExpenseRequest> saved = [];
  final List<({int consumptionId, int userId, String status})> statusUpdates =
      [];

  @override
  Future<List<GroupSummary>> fetchGroups(int userId) async => groups;

  @override
  Future<GroupSummary> createGroup({
    required String groupName,
    required List<int> userIds,
  }) async {
    if (shouldFail) {
      throw fakeFailure;
    }
    return GroupSummary(
      groupId: 500,
      groupName: groupName,
      invitationCode: 'ABC123',
    );
  }

  @override
  Future<void> addGroupMembers({
    required int groupId,
    required List<int> userIds,
  }) async {}

  @override
  Future<void> joinGroupByCode({
    required String invitationCode,
    required int userId,
  }) async {
    if (shouldFail) {
      throw fakeFailure;
    }
  }

  @override
  Future<void> leaveGroup({required int groupId, required int userId}) async {
    if (shouldFail) {
      throw fakeFailure;
    }
  }

  @override
  Future<List<GroupMember>> fetchGroupMembers(int groupId) async => members;

  @override
  Future<List<SplitExpense>> fetchExpenses(int userId) async => expenses;

  @override
  Future<void> saveExpense(SplitExpenseRequest request) async {
    if (shouldFail) {
      throw fakeFailure;
    }
    saved.add(request);
  }

  @override
  Future<void> deleteExpense(int consumptionId) async {
    if (shouldFail) {
      throw fakeFailure;
    }
  }

  @override
  Future<void> updateParticipantStatus({
    required int consumptionId,
    required int userId,
    required String status,
  }) async {
    if (shouldFail) {
      throw fakeFailure;
    }
    statusUpdates.add((
      consumptionId: consumptionId,
      userId: userId,
      status: status,
    ));
  }

  @override
  Future<List<Settlement>> fetchSettlements(int groupId) async => settlements;
}

/// Lets pending microtasks and zero-duration timers run.
Future<void> pump() => Future<void>.delayed(Duration.zero);
