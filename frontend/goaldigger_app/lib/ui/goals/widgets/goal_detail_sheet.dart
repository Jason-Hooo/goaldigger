import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/goal.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/sheets.dart';
import '../view_models/goals_view_model.dart';
import 'goal_labels.dart';

/// User intent chosen from a goal detail sheet.
sealed class GoalDetailAction {
  const GoalDetailAction();
}

final class EditGoal extends GoalDetailAction {
  const EditGoal();
}

final class DeleteGoal extends GoalDetailAction {
  const DeleteGoal();
}

final class AchieveGoal extends GoalDetailAction {
  const AchieveGoal();
}

final class AdjustGoal extends GoalDetailAction {
  const AdjustGoal(this.delta);

  final double delta;
}

/// Details of an in-progress goal. Pops with a [GoalDetailAction].
class GoalDetailSheet extends StatefulWidget {
  const GoalDetailSheet({super.key, required this.goal});

  final Goal goal;

  @override
  State<GoalDetailSheet> createState() => _GoalDetailSheetState();
}

class _GoalDetailSheetState extends State<GoalDetailSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController(text: '100');

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _adjust({required bool increase}) {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final amount = Formatters.parseAmount(_amountController.text)!;
    final error = GoalsViewModel.validateAdjustment(
      widget.goal,
      amount,
      increase: increase,
    );
    if (error != null) {
      ScaffoldMessenger.of(context).showMessage(error);
      return;
    }
    Navigator.pop(context, AdjustGoal(increase ? amount : -amount));
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    void pop(GoalDetailAction action) => Navigator.pop(context, action);

    return SheetBody(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(goal.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              goal.description,
              style: const TextStyle(color: AppColors.inkLight),
            ),
            const SizedBox(height: 12),
            if (goal.isFailed)
              const InlineBanner(message: '目標已過期失敗，無法解鎖成就'),
            const SizedBox(height: 18),
            DetailRow(label: '期限', value: goal.deadlineLabel),
            DetailRow(label: '目標金額', value: goal.targetAmountLabel),
            DetailRow(label: '目前已存', value: goal.savedAmountLabel),
            DetailRow(label: '還差', value: goal.remainingAmountLabel),
            const SizedBox(height: 12),
            AppProgressBar(value: goal.progress),
            const SizedBox(height: 8),
            Text('目前進度 ${goal.progressLabel}'),
            const SizedBox(height: 18),
            if (!goal.isFailed) ...[
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: '調整金額',
                  hintText: '例如 100',
                ),
                validator: Validators.positiveAmount,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _adjust(increase: true),
                      icon: const Icon(Icons.add),
                      label: const Text('增加進度'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _adjust(increase: false),
                      icon: const Icon(Icons.remove),
                      label: const Text('減少進度'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => pop(const EditGoal()),
                    child: const Text('編輯'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => pop(const DeleteGoal()),
                    child: const Text('刪除'),
                  ),
                ),
              ],
            ),
            if (goal.canAchieve)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => pop(const AchieveGoal()),
                    icon: const Icon(Icons.emoji_events),
                    label: const Text('解鎖成就'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Details of an achieved goal. Pops with [DeleteGoal] when deleting.
class AchievedGoalDetailSheet extends StatelessWidget {
  const AchievedGoalDetailSheet({super.key, required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    return SheetBody(
      scrollable: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(goal.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            goal.description,
            style: const TextStyle(color: AppColors.inkLight),
          ),
          const SizedBox(height: 18),
          DetailRow(label: '期限', value: goal.deadlineLabel),
          DetailRow(label: '目標金額', value: goal.targetAmountLabel),
          DetailRow(label: '目前已存', value: goal.savedAmountLabel),
          DetailRow(label: '達成日期', value: goal.achievedAtLabel),
          const SizedBox(height: 12),
          const AppProgressBar(value: 1, color: AppColors.green),
          const SizedBox(height: 8),
          const Text('進度 100%'),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, const DeleteGoal()),
            child: const Text('刪除目標'),
          ),
        ],
      ),
    );
  }
}
