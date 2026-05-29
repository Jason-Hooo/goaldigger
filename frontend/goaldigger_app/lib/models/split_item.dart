part of '../main.dart';

class SplitItem {
  SplitItem({
    this.consumptionId,
    this.groupId,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    this.groupMode = '建立群組',
    this.members = const [],
    this.proportions = const [],
    this.syncedToLedger = false,
    this.confirmationSent = false,
  });

  final int? consumptionId;
  final int? groupId;
  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;
  final String groupMode;
  final List<String> members;
  final List<double> proportions;
  final bool syncedToLedger;
  final bool confirmationSent;

  String get memberSummary {
    if (members.isEmpty) {
      return '尚未設定成員';
    }
    return members.join('、');
  }

  String get proportionSummary {
    if (proportions.isEmpty) {
      return '未設定比例';
    }
    return proportions
        .map((value) => '${(value * 100).toStringAsFixed(0)}%')
        .join(' / ');
  }
}

class GroupMember {
  GroupMember({
    required this.userId,
    required this.userName,
  });

  final int userId;
  final String userName;

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['user_id'] as int,
      userName: json['user_name'] as String? ?? '',
    );
  }
}
