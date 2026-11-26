/// A bill-splitting group.
class GroupSummary {
  const GroupSummary({
    required this.groupId,
    required this.groupName,
    required this.invitationCode,
  });

  factory GroupSummary.fromJson(Map<String, dynamic> json) {
    return GroupSummary(
      groupId: json['group_id'] as int,
      groupName: json['group_name'] as String? ?? '未命名群組',
      invitationCode: json['invitation_code'] as String? ?? '',
    );
  }

  final int groupId;
  final String groupName;
  final String invitationCode;
}

class GroupMember {
  const GroupMember({required this.userId, required this.userName});

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['user_id'] as int,
      userName: json['user_name'] as String? ?? '',
    );
  }

  final int userId;
  final String userName;

  String get initial => userName.isNotEmpty ? userName[0] : '?';
}

class SplitParticipant {
  const SplitParticipant({
    required this.userId,
    required this.userName,
    required this.sharedAmount,
    required this.isPayer,
    this.status,
  });

  factory SplitParticipant.fromJson(Map<String, dynamic> json) {
    return SplitParticipant(
      userId: json['user_id'] as int,
      userName: json['user_name'] as String? ?? '成員',
      sharedAmount: (json['shared_amount'] as num?)?.toDouble() ?? 0,
      isPayer: json['is_payer'] as bool? ?? false,
      status: json['status'] as String?,
    );
  }

  static const String statusPaid = 'paid';
  static const String statusPending = 'pending';

  final int userId;
  final String userName;
  final double sharedAmount;
  final bool isPayer;
  final String? status;

  bool get isPaid => status == statusPaid;

  /// Missing status is treated as pending.
  bool get isPending => (status ?? statusPending) == statusPending;

  String get initial => userName.isNotEmpty ? userName[0] : '?';

  SplitParticipant copyWith({String? status}) {
    return SplitParticipant(
      userId: userId,
      userName: userName,
      sharedAmount: sharedAmount,
      isPayer: isPayer,
      status: status ?? this.status,
    );
  }
}

/// What the current user is owed or owes for a single split expense.
class SplitBalance {
  const SplitBalance({
    required this.isPayer,
    required this.receivable,
    required this.payable,
    required this.share,
  });

  final bool isPayer;

  /// Unpaid shares of other participants (only when the user is the payer).
  final double receivable;

  /// The user's own unpaid share (only when the user is not the payer).
  final double payable;

  /// The user's own share of the expense.
  final double share;

  bool get isSettled => isPayer ? receivable <= 0 : payable <= 0;
}

/// A group expense and how it is split between participants.
class SplitExpense {
  const SplitExpense({
    required this.consumptionId,
    required this.groupId,
    required this.groupName,
    required this.name,
    required this.amount,
    required this.createdAt,
    required this.participants,
  });

  factory SplitExpense.fromJson(Map<String, dynamic> json) {
    return SplitExpense(
      consumptionId: json['consumption_id'] as int,
      groupId: json['group_id'] as int,
      groupName: json['group_name'] as String? ?? '未命名群組',
      name: json['name'] as String? ?? '分帳',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      participants: (json['participants'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SplitParticipant.fromJson)
          .toList(),
    );
  }

  final int consumptionId;
  final int groupId;
  final String groupName;
  final String name;
  final double amount;
  final DateTime createdAt;
  final List<SplitParticipant> participants;

  SplitParticipant? participantFor(int userId) {
    for (final participant in participants) {
      if (participant.userId == userId) {
        return participant;
      }
    }
    return null;
  }

  SplitParticipant? get payer {
    for (final participant in participants) {
      if (participant.isPayer) {
        return participant;
      }
    }
    return null;
  }

  SplitBalance balanceFor(int userId) {
    final current = participantFor(userId);
    final isPayer = current?.isPayer ?? false;
    final receivable = isPayer
        ? participants
              .where((p) => p.userId != userId && !p.isPaid)
              .fold<double>(0, (sum, p) => sum + p.sharedAmount)
        : 0.0;
    final payable = !isPayer && current != null && !current.isPaid
        ? current.sharedAmount
        : 0.0;
    return SplitBalance(
      isPayer: isPayer,
      receivable: receivable,
      payable: payable,
      share: current?.sharedAmount ?? 0,
    );
  }

  SplitExpense copyWith({List<SplitParticipant>? participants}) {
    return SplitExpense(
      consumptionId: consumptionId,
      groupId: groupId,
      groupName: groupName,
      name: name,
      amount: amount,
      createdAt: createdAt,
      participants: participants ?? this.participants,
    );
  }
}

/// One member's share in a split expense request.
class SplitShare {
  const SplitShare({required this.userId, required this.sharedAmount});

  final int userId;
  final double sharedAmount;

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'shared_amount': sharedAmount,
  };
}

/// Payload for creating or updating a split expense.
class SplitExpenseRequest {
  const SplitExpenseRequest({
    this.consumptionId,
    required this.groupId,
    required this.name,
    required this.amount,
    required this.payerId,
    required this.shares,
    this.typeId,
  });

  /// `null` when creating a new expense.
  final int? consumptionId;
  final int groupId;
  final String name;
  final double amount;
  final int payerId;
  final int? typeId;
  final List<SplitShare> shares;

  Map<String, dynamic> toJson() => {
    'group_id': groupId,
    'name': name,
    'amount': amount,
    'payer_id': payerId,
    'type_id': typeId,
    'split_details': shares.map((share) => share.toJson()).toList(),
  };
}

/// A suggested transfer to settle a group's balances.
class Settlement {
  const Settlement({
    required this.fromName,
    required this.toName,
    required this.amount,
  });

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      fromName: json['from_name']?.toString() ?? '',
      toName: json['to_name']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }

  final String fromName;
  final String toName;
  final double amount;
}
