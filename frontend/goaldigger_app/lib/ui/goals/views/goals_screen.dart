import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/result/result.dart';
import '../../../data/models/goal.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/sheets.dart';
import '../view_models/goals_view_model.dart';
import '../widgets/goal_detail_sheet.dart';
import '../widgets/goal_editor_sheet.dart';
import '../widgets/goal_widgets.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GoalsViewModel>();
    final errorMessage = viewModel.errorMessage;
    final currentGoals = viewModel.currentGoals;
    final achievedGoals = viewModel.achievedGoals;

    return Stack(
      children: [
        PageScaffold(
          title: '目標',
          subtitle: '把想買的東西、金額和期限先記下來。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              GoalSummaryCard(
                totalSaved: viewModel.totalSaved,
                totalTarget: viewModel.totalTarget,
                completionRate: viewModel.overallProgress,
                goalCount: currentGoals.length,
              ),
              const SizedBox(height: 20),
              const SectionHeader(title: '當前目標'),
              const SizedBox(height: 12),
              if (viewModel.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (errorMessage != null)
                ErrorStateCard(message: errorMessage, onRetry: viewModel.load)
              else if (currentGoals.isEmpty)
                const EmptyStateCard(
                  icon: Icons.flag_rounded,
                  message: '還沒有任何進行中的目標，先按右下角新增一個。',
                )
              else
                for (final goal in currentGoals)
                  GoalTile(goal: goal, onTap: () => _openDetail(context, goal)),
              const SizedBox(height: 20),
              const SectionHeader(title: '目標成就表'),
              const SizedBox(height: 12),
              if (achievedGoals.isEmpty)
                const EmptyStateCard(
                  icon: Icons.emoji_events,
                  message: '目前還沒有完成的目標。',
                )
              else
                for (final goal in achievedGoals)
                  GoalAchievementTile(
                    goal: goal,
                    onTap: () => _openDetail(context, goal),
                  ),
            ],
          ),
        ),
        PageFab(heroTag: 'fab-goals', onPressed: () => _openEditor(context)),
      ],
    );
  }

  Future<void> _openDetail(BuildContext context, Goal goal) async {
    final action = await showAppBottomSheet<GoalDetailAction>(
      context,
      builder: (_) => goal.isAchieved
          ? AchievedGoalDetailSheet(goal: goal)
          : GoalDetailSheet(goal: goal),
    );
    if (action == null || !context.mounted) {
      return;
    }

    final viewModel = context.read<GoalsViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    switch (action) {
      case EditGoal():
        await _openEditor(context, goal);
      case DeleteGoal():
        await _confirmDelete(context, goal);
      case AdjustGoal(:final delta):
        final result = await viewModel.adjustSavedAmount(goal, delta);
        messenger.showMessage(switch (result) {
          Success() => '${delta >= 0 ? '增加' : '減少'}目標進度：${goal.title}',
          Failure(:final message) => message,
        });
      case AchieveGoal():
        final result = await viewModel.achieve(goal);
        messenger.showMessage(switch (result) {
          Success() => '🎉 恭喜！目標已達成！',
          Failure(:final message) => message,
        });
    }
  }

  Future<void> _openEditor(BuildContext context, [Goal? initialGoal]) async {
    final viewModel = context.read<GoalsViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final goal = await showAppBottomSheet<Goal>(
      context,
      builder: (_) => GoalEditorSheet(initialGoal: initialGoal),
    );
    if (goal == null) {
      return;
    }

    final isNew = initialGoal == null;
    final result = await viewModel.save(goal, isNew: isNew);
    messenger.showMessage(switch (result) {
      Success() => '${isNew ? '已新增' : '已更新'}目標：${goal.title}',
      Failure(:final message) => message,
    });
  }

  Future<void> _confirmDelete(BuildContext context, Goal goal) async {
    final viewModel = context.read<GoalsViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: '刪除目標',
      message: '確定要刪除「${goal.title}」嗎？\n這個操作無法復原。',
      confirmLabel: '確認刪除',
    );
    if (!confirmed) {
      return;
    }

    final result = await viewModel.delete(goal);
    messenger.showMessage(switch (result) {
      Success() => '已刪除 ${goal.title}',
      Failure(:final message) => message,
    });
  }
}
