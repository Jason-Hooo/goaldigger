import '../../../core/utils/formatters.dart';
import '../../../data/models/goal.dart';

/// Display strings for a [Goal], kept out of the data model.
extension GoalLabels on Goal {
  String get deadlineLabel => Formatters.date(deadline);

  String get targetAmountLabel => '\$${Formatters.money(targetAmount)}';

  String get savedAmountLabel => '\$${Formatters.money(savedAmount)}';

  /// Never negative: an over-saved goal shows `$0`.
  String get remainingAmountLabel {
    final remaining = remainingAmount;
    return remaining <= 0 ? '\$0' : '\$${Formatters.money(remaining)}';
  }

  String get progressLabel => '${(progress * 100).toStringAsFixed(0)}%';

  String get achievedAtLabel {
    final achievedAt = this.achievedAt;
    if (achievedAt == null) {
      return isAchieved ? '已達成' : '尚未達成';
    }
    return Formatters.date(achievedAt);
  }
}
