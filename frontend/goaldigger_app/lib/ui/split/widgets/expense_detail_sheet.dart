import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/result/result.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/split.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/sheets.dart';
import '../view_models/group_detail_view_model.dart';

enum ExpenseDetailAction { edit, delete }

/// Details of a split expense. Reads live data from [GroupDetailViewModel]
/// so repayment confirmations are reflected immediately. Pops with an
/// [ExpenseDetailAction].
class ExpenseDetailSheet extends StatelessWidget {
  const ExpenseDetailSheet({super.key, required this.initialExpense});

  final SplitExpense initialExpense;

  Future<void> _confirmRepayment(
    BuildContext context,
    SplitExpense expense,
    SplitParticipant participant,
  ) async {
    final viewModel = context.read<GroupDetailViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: '確認還款',
      message:
          '確定要確認 ${participant.userName} 已經還款 '
          '\$${participant.sharedAmount.toStringAsFixed(0)} 嗎？',
    );
    if (!confirmed) {
      return;
    }
    final result = await viewModel.confirmRepayment(expense, participant);
    if (result case Failure(:final message)) {
      messenger.showMessage(
        '確認還款失敗：$message',
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GroupDetailViewModel>();
    final expense =
        viewModel.expenseById(initialExpense.consumptionId) ?? initialExpense;
    final balance = expense.balanceFor(viewModel.userId);
    final payer = expense.payer;

    return SheetBody(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(expense.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            expense.groupName,
            style: const TextStyle(color: AppColors.inkLight),
          ),
          const SizedBox(height: 18),
          DetailRow(
            label: '金額',
            value: '\$${expense.amount.toStringAsFixed(0)}',
          ),
          DetailRow(
            label: '建立時間',
            value: Formatters.dateTime(expense.createdAt),
          ),
          DetailRow(label: '成員數', value: '${expense.participants.length} 人'),
          if (payer != null) DetailRow(label: '代墊者', value: payer.userName),
          DetailRow(label: '你的角色', value: balance.isPayer ? '代墊者' : '分攤者'),
          DetailRow(
            label: balance.isPayer ? '待收金額' : '待付金額',
            value: '\$${balance.share.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 18),
          const Text(
            '分攤明細',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          for (final participant in expense.participants)
            _ParticipantRow(
              participant: participant,
              canConfirmRepayment:
                  balance.isPayer &&
                  !participant.isPayer &&
                  participant.isPending,
              onConfirmRepayment: () =>
                  _confirmRepayment(context, expense, participant),
            ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.pop(context, ExpenseDetailAction.edit),
                  child: const Text('編輯'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(context, ExpenseDetailAction.delete),
                  child: const Text('刪除'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({
    required this.participant,
    required this.canConfirmRepayment,
    required this.onConfirmRepayment,
  });

  final SplitParticipant participant;
  final bool canConfirmRepayment;
  final VoidCallback onConfirmRepayment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: participant.isPayer
                ? AppColors.pinkPrimary
                : AppColors.pinkPrimary.withValues(alpha: 0.3),
            child: Text(
              participant.initial,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.userName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (participant.isPayer)
                  const Text(
                    '代墊者',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.pinkPrimary,
                    ),
                  )
                else if (participant.isPaid)
                  const Text(
                    '已還款',
                    style: TextStyle(fontSize: 12, color: Colors.green),
                  ),
              ],
            ),
          ),
          if (canConfirmRepayment)
            TextButton(
              onPressed: onConfirmRepayment,
              child: const Text(
                '確認還款',
                style: TextStyle(color: AppColors.pinkPrimary),
              ),
            ),
          Text(
            '\$${participant.sharedAmount.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
