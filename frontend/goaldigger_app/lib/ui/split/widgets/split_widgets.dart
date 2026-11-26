import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/split.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/sheets.dart';

class SplitSummaryCard extends StatelessWidget {
  const SplitSummaryCard({
    super.key,
    required this.groupCount,
    required this.payableTotal,
    required this.receivableTotal,
  });

  final int groupCount;
  final double payableTotal;
  final double receivableTotal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('分帳總覽', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('$groupCount 個群組', style: textTheme.headlineSmall),
            const SizedBox(height: 16),
            Row(
              children: [
                StatChip(
                  label: '待付',
                  value: payableTotal,
                  color: AppColors.pinkPrimary,
                ),
                const SizedBox(width: 12),
                StatChip(
                  label: '待收',
                  value: receivableTotal,
                  color: AppColors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.group, required this.onTap});

  final GroupSummary group;
  final VoidCallback onTap;

  Future<void> _copyCode(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: group.invitationCode));
    messenger.showMessage('邀請碼已複製', duration: const Duration(seconds: 2));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.pinkPrimary.withValues(alpha: 0.15),
          child: const Icon(Icons.group, color: AppColors.pinkPrimary),
        ),
        title: Text(group.groupName),
        subtitle: Row(
          children: [
            Text('邀請碼: ${group.invitationCode}'),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _copyCode(context),
              child: const Icon(
                Icons.content_copy,
                size: 16,
                color: AppColors.pinkPrimary,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

/// Navigation-style action row on the group detail page.
class GroupActionTile extends StatelessWidget {
  const GroupActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = AppColors.pinkPrimary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class GroupExpenseTile extends StatelessWidget {
  const GroupExpenseTile({
    super.key,
    required this.expense,
    required this.currentUserId,
    required this.onTap,
  });

  final SplitExpense expense;
  final int currentUserId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final balance = expense.balanceFor(currentUserId);
    final isPayer = balance.isPayer;
    final (statusText, statusColor) = switch (balance) {
      SplitBalance(isPayer: true, isSettled: false) => ('待收', AppColors.green),
      SplitBalance(isPayer: true) => ('已收齊', AppColors.settled),
      SplitBalance(isSettled: false) => ('待付', AppColors.pinkPrimary),
      _ => ('已還款', AppColors.settled),
    };
    final accent = isPayer ? AppColors.green : AppColors.pinkPrimary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accent.withValues(alpha: 0.15),
          child: Icon(
            isPayer ? Icons.arrow_upward : Icons.arrow_downward,
            color: accent,
          ),
        ),
        title: Text(expense.name),
        subtitle: Text(
          '${Formatters.dateTime(expense.createdAt)} · '
          '${expense.participants.length} 位成員',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${expense.amount.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              statusText,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
