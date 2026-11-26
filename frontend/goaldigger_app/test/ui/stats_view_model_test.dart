import 'package:flutter_test/flutter_test.dart';
import 'package:goaldigger_app/data/models/expense_type.dart';
import 'package:goaldigger_app/data/models/ledger_record.dart';
import 'package:goaldigger_app/data/models/stats.dart';
import 'package:goaldigger_app/ui/stats/view_models/stats_view_model.dart';

void main() {
  const types = [
    ExpenseType(id: 1, name: '餐飲', isExpense: true),
    ExpenseType(id: 2, name: '薪資', isExpense: false),
  ];

  LedgerRecord record(int id, int typeId, double amount, DateTime at) =>
      LedgerRecord(
        recordId: id,
        typeId: typeId,
        amount: amount,
        createdAt: at,
        description: 'R$id',
      );

  test('buildMonthly buckets six months ending with the current one', () {
    final months = StatsViewModel.buildMonthly(
      DateTime(2026, 2, 15),
      [
        record(1, 1, 10, DateTime(2026, 2, 1)),
        record(2, 2, 100, DateTime(2026, 2, 28)),
        record(3, 1, 5, DateTime(2025, 9, 30)),
        record(4, 1, 99, DateTime(2025, 8, 31)), // outside window
      ],
      types,
    );

    expect(months.map((m) => m.month.month), [9, 10, 11, 12, 1, 2]);
    expect(months.first.expense, 5);
    expect(months.last.expense, 10);
    expect(months.last.income, 100);
    expect(months.last.isCurrentMonth, isTrue);
    expect(months.first.isCurrentMonth, isFalse);
  });

  test('buildCategoryShares computes percentages and income flag', () {
    final shares = StatsViewModel.buildCategoryShares(const [
      CategoryStat(category: '餐飲', amount: 25),
      CategoryStat(category: '薪資', amount: 75),
    ], types);

    expect(shares.map((s) => s.percentage), [0.25, 0.75]);
    expect(shares.last.isIncome, isTrue);
    expect(StatsViewModel.buildCategoryShares(const [], types), isEmpty);
  });

  test('buildRecentExpenses excludes income and sorts newest first', () {
    final recent = StatsViewModel.buildRecentExpenses([
      record(1, 1, 10, DateTime(2026, 1, 1)),
      record(2, 2, 100, DateTime(2026, 1, 5)),
      record(3, 1, 20, DateTime(2026, 1, 3)),
    ], types);

    expect(recent.map((r) => r.title), ['R3', 'R1']);
    expect(recent.first.category, '餐飲');
  });
}
