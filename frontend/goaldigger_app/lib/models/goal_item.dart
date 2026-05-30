part of '../main.dart';

class GoalItem {
  GoalItem({
    this.goalId,
    required this.title,
    required this.description,
    required this.targetAmount,
    required this.deadline,
    this.savedAmount = 0,
    this.achievedAt,
    this.status,
  });

  final int? goalId;
  final String title;
  final String description;
  final double targetAmount;
  final DateTime deadline;
  final double savedAmount;
  final DateTime? achievedAt;
  final String? status;

  bool get isAchieved => achievedAt != null || status == 'achieved';
  bool get isFailed => status == 'failed' || (deadline.isBefore(DateTime.now()) && !isAchieved);
  bool get canAchieve => progress >= 1 && !isAchieved && !isFailed && !deadline.isBefore(DateTime.now());

  String get achievedAtLabel {
    final achievedAt = this.achievedAt;
    if (achievedAt == null) {
      return isAchieved ? '已達成' : '尚未達成';
    }
    return '${achievedAt.year}/${_twoDigits(achievedAt.month)}/${_twoDigits(achievedAt.day)}';
  }

  double get progress {
    if (targetAmount <= 0) {
      return 0;
    }
    return (savedAmount / targetAmount).clamp(0.0, 1.0).toDouble();
  }

  double get remainingAmount {
    return targetAmount - savedAmount;
  }

  String get deadlineLabel {
    return '${deadline.year}/${_twoDigits(deadline.month)}/${_twoDigits(deadline.day)}';
  }

  String get targetAmountLabel => '\$${_formatMoney(targetAmount)}';

  String get savedAmountLabel => '\$${_formatMoney(savedAmount)}';

  String get remainingAmountLabel => '\$${_formatMoney(remainingAmount)}';

  String get progressLabel => '${(progress * 100).toStringAsFixed(0)}%';

  GoalItem copyWith({
    int? goalId,
    String? title,
    String? description,
    double? targetAmount,
    DateTime? deadline,
    double? savedAmount,
    DateTime? achievedAt,
    String? status,
  }) {
    return GoalItem(
      goalId: goalId ?? this.goalId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      deadline: deadline ?? this.deadline,
      savedAmount: savedAmount ?? this.savedAmount,
      achievedAt: achievedAt ?? this.achievedAt,
      status: status ?? this.status,
    );
  }
}

String _formatMoney(double value) {
  final whole = value.toStringAsFixed(0);
  return whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
