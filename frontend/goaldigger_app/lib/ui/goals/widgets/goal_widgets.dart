import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/goal.dart';
import '../../core/widgets/common_widgets.dart';
import 'goal_labels.dart';

class GoalSummaryCard extends StatelessWidget {
  const GoalSummaryCard({
    super.key,
    required this.totalSaved,
    required this.totalTarget,
    required this.completionRate,
    required this.goalCount,
  });

  final double totalSaved;
  final double totalTarget;
  final double completionRate;
  final int goalCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('當前目標總覽', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                StatChip(
                  label: '目前已存',
                  value: totalSaved,
                  color: AppColors.green,
                ),
                const SizedBox(width: 12),
                StatChip(
                  label: '當前目標',
                  value: totalTarget,
                  color: AppColors.pinkPrimary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppProgressBar(value: completionRate),
            const SizedBox(height: 8),
            Text(
              '目前有 $goalCount 個目標・完成率 '
              '${(completionRate * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: AppColors.inkLight),
            ),
          ],
        ),
      ),
    );
  }
}

class GoalTile extends StatelessWidget {
  const GoalTile({super.key, required this.goal, this.onTap});

  final Goal goal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          goal.description,
                          style: const TextStyle(color: AppColors.inkLight),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        goal.progressLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.pinkPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        goal.deadlineLabel,
                        style: const TextStyle(color: AppColors.inkLight),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppProgressBar(value: goal.progress),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('已存 ${goal.savedAmountLabel}'),
                  const Spacer(),
                  Text('目標 ${goal.targetAmountLabel}'),
                  const SizedBox(width: 12),
                  Text('還差 ${goal.remainingAmountLabel}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GoalAchievementTile extends StatelessWidget {
  const GoalAchievementTile({
    super.key,
    required this.goal,
    required this.onTap,
  });

  final Goal goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.green.withValues(alpha: 0.15),
            child: const Icon(Icons.emoji_events, color: AppColors.green),
          ),
          title: Text(goal.title),
          subtitle: Text('${goal.description}\n達成日期：${goal.achievedAtLabel}'),
          isThreeLine: true,
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                goal.targetAmountLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                '已達成',
                style: TextStyle(
                  color: AppColors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
