import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../view_models/ledger_entry.dart';

/// Icon representing a ledger category.
IconData ledgerCategoryIcon(String category, {required bool isIncome}) {
  if (isIncome) {
    return switch (category) {
      '薪資' => Icons.payments,
      '獎金' => Icons.workspace_premium,
      '退款' => Icons.keyboard_return,
      _ => Icons.savings,
    };
  }
  return switch (category) {
    '餐飲' => Icons.local_cafe,
    '購物' => Icons.shopping_bag,
    '交通' => Icons.directions_bus,
    '帳單' => Icons.receipt_long,
    _ => Icons.payments,
  };
}

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
  });

  final double balance;
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('本月結餘', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '\$${balance.toStringAsFixed(2)}',
              style: textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                StatChip(label: '收入', value: income, color: AppColors.green),
                const SizedBox(width: 12),
                StatChip(
                  label: '支出',
                  value: expense,
                  color: AppColors.pinkPrimary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LedgerTile extends StatelessWidget {
  const LedgerTile({super.key, required this.entry, this.onTap});

  final LedgerEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.pinkSoft,
          child: Icon(
            ledgerCategoryIcon(entry.categoryName, isIncome: entry.isIncome),
            color: AppColors.pinkPrimary,
          ),
        ),
        title: Text(entry.title),
        subtitle: Text(entry.subtitle),
        trailing: Text(
          entry.amountLabel,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: entry.isIncome ? AppColors.green : AppColors.pinkPrimary,
          ),
        ),
      ),
    );
  }
}
