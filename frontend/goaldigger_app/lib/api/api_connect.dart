part of '../main.dart';

class ApiException implements Exception {
  ApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      statusCode == null ? message : '$message (HTTP $statusCode)';
}

class AuthUser {
  AuthUser({required this.userId, required this.name, required this.email});

  final int userId;
  final String name;
  final String email;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      userId: json['user_id'] as int,
      name: json['name'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
    );
  }
}

class ExpenseType {
  ExpenseType({
    required this.id,
    required this.name,
    required this.isExpense,
    this.ownerUserId,
  });

  final int id;
  final String name;
  final bool isExpense;
  final int? ownerUserId;

  bool get isCustom => ownerUserId != null;

  factory ExpenseType.fromJson(Map<String, dynamic> json) {
    return ExpenseType(
      id: json['type_id'] as int,
      name: json['type_name'] as String? ?? '未分類',
      isExpense: json['is_expense'] as bool? ?? true,
      ownerUserId: json['user_id'] as int?,
    );
  }
}

class LedgerRecord {
  LedgerRecord({
    required this.recordId,
    required this.typeId,
    required this.amount,
    required this.createdAt,
    this.description,
    this.typeName,
    this.isExpense,
    this.goalId,
    this.groupConsumptionId,
  });

  final int recordId;
  final int typeId;
  final double amount;
  final DateTime createdAt;
  final String? description;
  final String? typeName;
  final bool? isExpense;
  final int? goalId;
  final int? groupConsumptionId;

  factory LedgerRecord.fromJson(Map<String, dynamic> json) {
    return LedgerRecord(
      recordId: json['consumption_id'] as int,
      typeId: json['type_id'] as int,
      amount: (json['amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      description: json['description'] as String?,
      typeName: json['type_name'] as String?,
      isExpense: json['is_expense'] as bool?,
      goalId: json['goal_id'] as int?,
      groupConsumptionId: json['group_consumption_id'] as int?,
    );
  }
}

class CategoryStat {
  CategoryStat({required this.category, required this.amount});

  final String category;
  final double amount;

  factory CategoryStat.fromJson(Map<String, dynamic> json) {
    return CategoryStat(
      category: json['category'] as String? ?? '未分類',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class TrendPoint {
  TrendPoint({required this.date, required this.totalAmount});

  final DateTime date;
  final double totalAmount;

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      date: DateTime.parse(json['date'] as String),
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class GroupSummary {
  GroupSummary({
    required this.groupId,
    required this.groupName,
    required this.invitationCode,
  });

  final int groupId;
  final String groupName;
  final String invitationCode;

  factory GroupSummary.fromJson(Map<String, dynamic> json) {
    return GroupSummary(
      groupId: json['group_id'] as int,
      groupName: json['group_name'] as String? ?? '未命名群組',
      invitationCode: json['invitation_code'] as String? ?? '',
    );
  }
}

class SplitParticipant {
  SplitParticipant({
    required this.userId,
    required this.userName,
    required this.sharedAmount,
    required this.isPayer,
    this.status,
  });

  final int userId;
  final String userName;
  final double sharedAmount;
  final bool isPayer;
  final String? status;

  factory SplitParticipant.fromJson(Map<String, dynamic> json) {
    return SplitParticipant(
      userId: json['user_id'] as int,
      userName: json['user_name'] as String? ?? '成員',
      sharedAmount: (json['shared_amount'] as num?)?.toDouble() ?? 0,
      isPayer: json['is_payer'] as bool? ?? false,
      status: json['status'] as String?,
    );
  }
}

class SplitExpense {
  SplitExpense({
    required this.consumptionId,
    required this.groupId,
    required this.groupName,
    required this.name,
    required this.amount,
    required this.createdAt,
    required this.participants,
  });

  final int consumptionId;
  final int groupId;
  final String groupName;
  final String name;
  final double amount;
  final DateTime createdAt;
  final List<SplitParticipant> participants;

  factory SplitExpense.fromJson(Map<String, dynamic> json) {
    final participantsJson = (json['participants'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(SplitParticipant.fromJson)
        .toList();
    return SplitExpense(
      consumptionId: json['consumption_id'] as int,
      groupId: json['group_id'] as int,
      groupName: json['group_name'] as String? ?? '未命名群組',
      name: json['name'] as String? ?? '分帳',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      participants: participantsJson,
    );
  }
}

class ApiConnect {
  String token = '';

  String get baseUrl {
    return 'https://unloader-grill-glisten.ngrok-free.dev';
  }

  Map<String, String> get _jsonHeaders => const {
        'Content-Type': 'application/json',
      };

  Uri _buildUri(String path, [Map<String, String>? query]) {
    return Uri.parse('$baseUrl$path').replace(queryParameters: query);
  }

  dynamic _decodeBody(http.Response response) {
    if (response.body.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return response.body;
    }
  }

  dynamic _handleResponse(http.Response response) {
    final body = _decodeBody(response);
    if (response.statusCode >= 400) {
      String message = 'Request failed.';
      if (body is Map<String, dynamic>) {
        message =
            body['detail']?.toString() ?? body['message']?.toString() ?? message;
      }
      throw ApiException(message, response.statusCode);
    }
    return body;
  }

  Future<AuthUser> login({required String email, required String password}) async {
    final response = await http.post(
      _buildUri('/auth/login'),
      headers: _jsonHeaders,
      body: jsonEncode({'email': email, 'password': password}),
    );
    final body = _handleResponse(response);
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return AuthUser.fromJson(data);
      }
    }
    throw ApiException('登入失敗，無法取得使用者資料');
  }

  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      _buildUri('/auth/register'),
      headers: _jsonHeaders,
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    final body = _handleResponse(response);
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return AuthUser.fromJson(data);
      }
    }
    throw ApiException('註冊失敗，無法取得使用者資料');
  }

  Future<void> deleteAccount({required int userId, required String password}) async {
    final response = await http.delete(
      _buildUri('/auth/delete'),
      headers: _jsonHeaders,
      body: jsonEncode({'user_id': userId, 'password': password}),
    );
    _handleResponse(response);
  }

  Future<List<ExpenseType>> fetchExpenseTypes(int userId) async {
    final response = await http.get(
      _buildUri('/ledger/types', {'user_id': '$userId'}),
    );
    final body = _handleResponse(response);
    final list = (body as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ExpenseType.fromJson)
        .toList();
    return list;
  }

  Future<ExpenseType> createExpenseType({
    required int userId,
    required String typeName,
    required bool isExpense,
  }) async {
    final response = await http.post(
      _buildUri('/ledger/types'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'user_id': userId,
        'type_name': typeName,
        'is_expense': isExpense,
      }),
    );
    final body = _handleResponse(response);
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return ExpenseType.fromJson(data);
      }
    }
    throw ApiException('新增類別失敗，未取得回傳資料');
  }

  Future<ExpenseType> updateExpenseType({
    required int typeId,
    required int userId,
    required String typeName,
    required bool isExpense,
  }) async {
    final response = await http.put(
      _buildUri('/ledger/types/$typeId'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'user_id': userId,
        'type_name': typeName,
        'is_expense': isExpense,
      }),
    );
    final body = _handleResponse(response);
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return ExpenseType.fromJson(data);
      }
    }
    throw ApiException('更新類別失敗，未取得回傳資料');
  }

  Future<void> deleteExpenseType({
    required int typeId,
    required int userId,
  }) async {
    final response = await http.delete(
      _buildUri('/ledger/types/$typeId', {'user_id': '$userId'}),
    );
    _handleResponse(response);
  }

  Future<List<LedgerRecord>> fetchLedgerHistory(int userId,
      {int limit = 50}) async {
    final response = await http.get(
      _buildUri('/ledger/history/$userId', {'limit': '$limit'}),
    );
    final body = _handleResponse(response);
    final list = (body as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(LedgerRecord.fromJson)
        .toList();
    return list;
  }

  Future<void> createLedger({
    required int userId,
    required int typeId,
    required double amount,
    String? description,
    int? goalId,
  }) async {
    final response = await http.post(
      _buildUri('/ledger/'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'user_id': userId,
        'type_id': typeId,
        'amount': amount,
        'description': description,
        'goal_id': goalId,
      }),
    );
    _handleResponse(response);
  }

  Future<void> updateLedger({
    required int recordId,
    required int userId,
    required int typeId,
    required double amount,
    String? description,
    int? goalId,
  }) async {
    final response = await http.put(
      _buildUri('/ledger/$recordId'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'user_id': userId,
        'type_id': typeId,
        'amount': amount,
        'description': description,
        'goal_id': goalId,
      }),
    );
    _handleResponse(response);
  }

  Future<void> deleteLedger(int recordId, {int? goalId}) async {
    final response = await http.delete(
      _buildUri('/ledger/$recordId', goalId == null ? null : {'goal_id': '$goalId'}),
    );
    _handleResponse(response);
  }

  Future<List<GoalItem>> fetchGoals(int userId) async {
    final response = await http.get(_buildUri('/goals/$userId'));
    final body = _handleResponse(response);
    final list = (body as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((json) {
      final deadline = json['deadline'] as String?;
      final completionDate = json['completion_date'] as String?;
      return GoalItem(
        goalId: json['goal_id'] as int?,
        title: json['goal_name'] as String? ?? '未命名目標',
        description: json['description'] as String? ?? '',
        targetAmount: (json['target_amount'] as num?)?.toDouble() ?? 0,
        deadline: deadline == null
            ? DateTime.now().add(const Duration(days: 30))
            : DateTime.parse(deadline),
        savedAmount: (json['cumulative_amount'] as num?)?.toDouble() ?? 0,
        achievedAt: completionDate == null
            ? null
            : DateTime.parse(completionDate),
        status: json['status'] as String?,
      );
    }).toList();
    return list;
  }

  Future<GoalItem> createGoal({
    required int userId,
    required String title,
    required String description,
    required double targetAmount,
    required DateTime deadline,
  }) async {
    final response = await http.post(
      _buildUri('/goals/'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'user_id': userId,
        'goal_name': title,
        'description': description,
        'target_amount': targetAmount,
        'deadline': deadline.toIso8601String().split('T').first,
      }),
    );
    final body = _handleResponse(response);
    if (body is Map<String, dynamic>) {
      final deadlineValue = body['deadline'] as String?;
      return GoalItem(
        goalId: body['goal_id'] as int?,
        title: body['goal_name'] as String? ?? title,
        description: body['description'] as String? ?? description,
        targetAmount: (body['target_amount'] as num?)?.toDouble() ?? targetAmount,
        deadline: deadlineValue == null
            ? deadline
            : DateTime.parse(deadlineValue),
        savedAmount: (body['cumulative_amount'] as num?)?.toDouble() ?? 0,
        status: body['status'] as String?,
      );
    }
    throw ApiException('新增目標失敗，未取得回傳資料');
  }

  Future<GoalItem> updateGoal({
    required int goalId,
    String? title,
    String? description,
    double? targetAmount,
    DateTime? deadline,
    double? savedAmount,
  }) async {
    final response = await http.put(
      _buildUri('/goals/$goalId'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'goal_name': title,
        'description': description,
        'target_amount': targetAmount,
        'deadline': deadline == null
            ? null
            : deadline.toIso8601String().split('T').first,
        'cumulative_amount': savedAmount,
      }),
    );
    final body = _handleResponse(response);
    if (body is Map<String, dynamic>) {
      final deadlineValue = body['deadline'] as String?;
      return GoalItem(
        goalId: body['goal_id'] as int?,
        title: body['goal_name'] as String? ?? title ?? '未命名目標',
        description: body['description'] as String? ?? description ?? '',
        targetAmount:
            (body['target_amount'] as num?)?.toDouble() ?? targetAmount ?? 0,
        deadline: deadlineValue == null
            ? (deadline ?? DateTime.now())
            : DateTime.parse(deadlineValue),
        savedAmount:
            (body['cumulative_amount'] as num?)?.toDouble() ?? savedAmount ?? 0,
        status: body['status'] as String?,
      );
    }
    throw ApiException('更新目標失敗，未取得回傳資料');
  }

  Future<void> deleteGoal(int goalId) async {
    final response = await http.delete(_buildUri('/goals/$goalId'));
    _handleResponse(response);
  }

  Future<void> achieveGoal(int goalId) async {
    final response = await http.post(_buildUri('/goals/achieve/$goalId'));
    _handleResponse(response);
  }

  Future<List<CategoryStat>> fetchCategoryStats(int userId) async {
    final response = await http.get(_buildUri('/stats/category/$userId'));
    final body = _handleResponse(response);
    final list = (body as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CategoryStat.fromJson)
        .toList();
    return list;
  }

  Future<List<TrendPoint>> fetchTrendStats(int userId, {int days = 30}) async {
    final response = await http.get(
      _buildUri('/stats/trend/$userId', {'days': '$days'}),
    );
    final body = _handleResponse(response);
    final list = (body as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(TrendPoint.fromJson)
        .toList();
    return list;
  }

  Future<List<GroupSummary>> fetchGroups(int userId) async {
    final response = await http.get(_buildUri('/splits/groups/$userId'));
    final body = _handleResponse(response);
    final list = (body as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(GroupSummary.fromJson)
        .toList();
    return list;
  }

  Future<GroupSummary> createGroup({
    required String groupName,
    required List<int> userIds,
  }) async {
    final response = await http.post(
      _buildUri('/splits/groups/'),
      headers: _jsonHeaders,
      body: jsonEncode({'group_name': groupName, 'user_ids': userIds}),
    );
    final body = _handleResponse(response);
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return GroupSummary.fromJson(data);
      }
    }
    throw ApiException('建立群組失敗，未取得回傳資料');
  }

  Future<void> addGroupMembers({
    required int groupId,
    required List<int> userIds,
  }) async {
    final response = await http.post(
      _buildUri('/splits/groups/$groupId/members'),
      headers: _jsonHeaders,
      body: jsonEncode({'user_ids': userIds}),
    );
    _handleResponse(response);
  }

  Future<void> joinGroupByCode({
    required String invitationCode,
    required int userId,
  }) async {
    final response = await http.post(
      _buildUri('/splits/groups/join-by-code'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'invitation_code': invitationCode,
        'user_id': userId,
      }),
    );
    _handleResponse(response);
  }

  Future<void> leaveGroup({
    required int groupId,
    required int userId,
  }) async {
    final response = await http.delete(
      _buildUri('/splits/groups/$groupId/members/$userId'),
      headers: _jsonHeaders,
    );
    _handleResponse(response);
  }

  Future<void> updateParticipantStatus({
    required int consumptionId,
    required int userId,
    required String status,
  }) async {
    final response = await http.put(
      _buildUri('/splits/expenses/$consumptionId/participants/$userId/status?status=$status'),
      headers: _jsonHeaders,
    );
    _handleResponse(response);
  }

  Future<List<ExpenseType>> getExpenseTypes() async {
    final response = await http.get(
      _buildUri('/ledger/types'),
      headers: _jsonHeaders,
    );
    final data = _handleResponse(response);
    return (data as List).map((json) => ExpenseType.fromJson(json)).toList();
  }

  Future<void> addSplitExpense({
    required int groupId,
    required String name,
    required double amount,
    required int payerId,
    int? typeId,
    required List<Map<String, dynamic>> splitDetails,
  }) async {
    final response = await http.post(
      _buildUri('/splits/expenses/create'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'group_id': groupId,
        'name': name,
        'amount': amount,
        'payer_id': payerId,
        'type_id': typeId,
        'split_details': splitDetails,
      }),
    );
    _handleResponse(response);
  }

  Future<List<SplitExpense>> fetchSplitExpenses(int userId) async {
    final response = await http.get(_buildUri('/splits/expenses/$userId'));
    final body = _handleResponse(response);
    final list = (body as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(SplitExpense.fromJson)
        .toList();
    return list;
  }

  Future<void> deleteSplitExpense(int consumptionId) async {
    final response = await http.delete(_buildUri('/splits/expenses/$consumptionId'));
    _handleResponse(response);
  }

  Future<void> updateSplitExpense({
    required int consumptionId,
    required int groupId,
    required String name,
    required double amount,
    required int payerId,
    int? typeId,
    required List<Map<String, dynamic>> splitDetails,
  }) async {
    final response = await http.put(
      _buildUri('/splits/expenses/$consumptionId'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'group_id': groupId,
        'name': name,
        'amount': amount,
        'payer_id': payerId,
        'type_id': typeId,
        'split_details': splitDetails,
      }),
    );
    _handleResponse(response);
  }

  Future<Map<String, dynamic>> settleGroupExpenses(int groupId) async {
    final response = await http.get(_buildUri('/splits/settle/$groupId'));
    final body = _handleResponse(response);
    if (body is Map<String, dynamic>) {
      return body;
    }
    throw ApiException('無法取得結算建議');
  }

  Future<List<GroupMember>> getGroupMembers(int groupId) async {
    final response = await http.get(_buildUri('/splits/groups/$groupId/members'));
    final body = _handleResponse(response);
    final list = (body as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(GroupMember.fromJson)
        .toList();
    return list;
  }
}
