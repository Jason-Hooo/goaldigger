/// A savings goal.
class Goal {
  const Goal({
    this.goalId,
    required this.title,
    required this.description,
    required this.targetAmount,
    required this.deadline,
    this.savedAmount = 0,
    this.achievedAt,
    this.status,
  });

  /// Parses a goal payload. Fields missing from the response fall back to
  /// [fallback] (typically the values that were just submitted).
  factory Goal.fromJson(Map<String, dynamic> json, {Goal? fallback}) {
    final deadline = json['deadline'] as String?;
    final completionDate = json['completion_date'] as String?;
    return Goal(
      goalId: json['goal_id'] as int? ?? fallback?.goalId,
      title: json['goal_name'] as String? ?? fallback?.title ?? '未命名目標',
      description:
          json['description'] as String? ?? fallback?.description ?? '',
      targetAmount:
          (json['target_amount'] as num?)?.toDouble() ??
          fallback?.targetAmount ??
          0,
      deadline: deadline != null
          ? DateTime.parse(deadline)
          : fallback?.deadline ??
                DateTime.now().add(const Duration(days: 30)),
      savedAmount:
          (json['cumulative_amount'] as num?)?.toDouble() ??
          fallback?.savedAmount ??
          0,
      achievedAt: completionDate != null
          ? DateTime.parse(completionDate)
          : null,
      status: json['status'] as String?,
    );
  }

  static const String statusAchieved = 'achieved';
  static const String statusFailed = 'failed';

  final int? goalId;
  final String title;
  final String description;
  final double targetAmount;
  final DateTime deadline;
  final double savedAmount;
  final DateTime? achievedAt;
  final String? status;

  bool get isAchieved => achievedAt != null || status == statusAchieved;

  bool get isExpired => deadline.isBefore(DateTime.now());

  bool get isFailed => status == statusFailed || (isExpired && !isAchieved);

  bool get canAchieve => progress >= 1 && !isAchieved && !isFailed;

  /// Completion ratio clamped to `[0, 1]`.
  double get progress {
    if (targetAmount <= 0) {
      return 0;
    }
    return (savedAmount / targetAmount).clamp(0.0, 1.0);
  }

  /// Remaining amount; may be negative when over-saved.
  double get remainingAmount => targetAmount - savedAmount;

  Goal copyWith({
    int? goalId,
    String? title,
    String? description,
    double? targetAmount,
    DateTime? deadline,
    double? savedAmount,
    DateTime? achievedAt,
    String? status,
  }) {
    return Goal(
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
