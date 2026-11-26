import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../view_models/stats_view_model.dart';

class OverviewCard extends StatelessWidget {
  const OverviewCard({super.key, required this.month});

  final MonthlySummary month;

  @override
  Widget build(BuildContext context) {
    final balance = month.balance;
    final isPositive = balance >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('本月概覽', style: Theme.of(context).textTheme.titleLarge),
                Text(
                  Formatters.yearMonth(month.month),
                  style: const TextStyle(color: AppColors.inkLight),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: '收入',
                  value: month.income,
                  color: AppColors.green,
                ),
                _StatItem(
                  label: '支出',
                  value: month.expense,
                  color: AppColors.pinkPrimary,
                ),
                _StatItem(
                  label: '結餘',
                  value: balance.abs(),
                  color: isPositive ? AppColors.green : AppColors.pinkPrimary,
                  isNegative: !isPositive,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    this.isNegative = false,
  });

  final String label;
  final double value;
  final Color color;
  final bool isNegative;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.inkLight),
        ),
        const SizedBox(height: 4),
        Text(
          '${isNegative ? '-' : ''}${moneyLabel(value)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class CategoryBreakdownCard extends StatelessWidget {
  const CategoryBreakdownCard({super.key, required this.shares});

  final List<CategoryShare> shares;

  @override
  Widget build(BuildContext context) {
    if (shares.isEmpty) {
      return const EmptyStateCard(
        icon: Icons.pie_chart,
        message: '尚無支出資料',
        padding: 20,
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('收入/支出分類', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            for (final share in shares)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CategoryBar(share: share),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.share});

  final CategoryShare share;

  @override
  Widget build(BuildContext context) {
    final color = share.isIncome ? AppColors.green : AppColors.pinkPrimary;
    final background = share.isIncome
        ? AppColors.green.withValues(alpha: 0.15)
        : AppColors.pinkSoft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(share.category),
            Text(
              '${moneyLabel(share.amount)} '
              '(${(share.percentage * 100).toStringAsFixed(0)}%)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AppProgressBar(
          value: share.percentage,
          color: color,
          backgroundColor: background,
          minHeight: 8,
          radius: 4,
        ),
      ],
    );
  }
}

class MonthlyTrendCard extends StatelessWidget {
  const MonthlyTrendCard({super.key, required this.months});

  static const double _barMaxHeight = 100;

  final List<MonthlySummary> months;

  @override
  Widget build(BuildContext context) {
    final maxExpense = months.fold<double>(
      0,
      (max, month) => month.expense > max ? month.expense : max,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('近六個月支出', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final month in months)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              moneyLabel(month.expense),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: _barMaxHeight,
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: 24,
                                height: maxExpense <= 0
                                    ? 0
                                    : _barMaxHeight *
                                          (month.expense / maxExpense),
                                decoration: BoxDecoration(
                                  color: month.isCurrentMonth
                                      ? AppColors.pinkPrimary
                                      : AppColors.pinkSoft,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${month.month.month}月',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecentExpensesCard extends StatelessWidget {
  const RecentExpensesCard({super.key, required this.expenses});

  final List<RecentExpense> expenses;

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const EmptyStateCard(
        icon: Icons.receipt_long,
        message: '尚無支出紀錄',
        padding: 20,
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('最近支出', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final expense in expenses) _RecentExpenseTile(expense: expense),
          ],
        ),
      ),
    );
  }
}

class _RecentExpenseTile extends StatelessWidget {
  const _RecentExpenseTile({required this.expense});

  final RecentExpense expense;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.pinkSoft,
            child: Text(
              '${expense.date.day}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.pinkPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${Formatters.monthDay(expense.date)} · ${expense.category}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.inkLight,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '-${moneyLabel(expense.amount)}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.pinkPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
