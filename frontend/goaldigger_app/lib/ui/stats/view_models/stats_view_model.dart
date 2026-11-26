import 'dart:async';

import '../../../core/utils/parallel.dart';
import '../../../data/models/expense_type.dart';
import '../../../data/models/ledger_record.dart';
import '../../../data/models/stats.dart';
import '../../../data/repositories/expense_type/expense_type_repository.dart';
import '../../../data/repositories/ledger/ledger_repository.dart';
import '../../../data/repositories/stats/stats_repository.dart';
import '../../../data/services/data_change_notifier.dart';
import '../../../data/services/realtime/realtime_service.dart';
import '../../core/view_models/auto_refresh_mixin.dart';
import '../../core/view_models/view_model.dart';

class MonthlySummary {
  const MonthlySummary({
    required this.month,
    required this.income,
    required this.expense,
    this.isCurrentMonth = false,
  });

  final DateTime month;
  final double income;
  final double expense;
  final bool isCurrentMonth;

  double get balance => income - expense;
}

class CategoryShare {
  const CategoryShare({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.isIncome,
  });

  final String category;
  final double amount;
  final double percentage;
  final bool isIncome;
}

class RecentExpense {
  const RecentExpense({
    required this.date,
    required this.title,
    required this.category,
    required this.amount,
  });

  final DateTime date;
  final String title;
  final String category;
  final double amount;
}

typedef _StatsSnapshot = ({
  List<MonthlySummary> monthly,
  List<CategoryShare> categories,
  List<RecentExpense> recent,
});

class StatsViewModel extends ViewModel with LoadStateMixin, AutoRefreshMixin {
  StatsViewModel({
    required this.userId,
    required LedgerRepository ledgerRepository,
    required ExpenseTypeRepository expenseTypeRepository,
    required StatsRepository statsRepository,
    required DataChangeNotifier dataChanges,
    required RealtimeService realtime,
    DateTime Function()? clock,
  }) : _ledgerRepository = ledgerRepository,
       _expenseTypeRepository = expenseTypeRepository,
       _statsRepository = statsRepository,
       _dataChanges = dataChanges,
       _realtime = realtime,
       _clock = clock ?? DateTime.now;

  static const int monthsInTrend = 6;
  static const int recentExpenseCount = 10;
  static const int historyLimit = 300;

  final int userId;
  final LedgerRepository _ledgerRepository;
  final ExpenseTypeRepository _expenseTypeRepository;
  final StatsRepository _statsRepository;
  final DataChangeNotifier _dataChanges;
  final RealtimeService _realtime;
  final DateTime Function() _clock;

  List<MonthlySummary> _monthly = const [];
  List<CategoryShare> _categories = const [];
  List<RecentExpense> _recent = const [];

  List<MonthlySummary> get monthly => _monthly;
  List<CategoryShare> get categories => _categories;
  List<RecentExpense> get recentExpenses => _recent;

  MonthlySummary get currentMonth => _monthly.isEmpty
      ? MonthlySummary(month: _clock(), income: 0, expense: 0)
      : _monthly.last;

  void init() {
    unawaited(load());
    listenToDataChanges(_dataChanges, () => load(silent: true));
    watchRealtime(
      _realtime,
      channelName: 'stats-$userId',
      tables: const ['personal_consumptions', 'expense_types'],
      onChange: () => load(silent: true),
    );
  }

  Future<void> load({bool silent = false}) {
    return runLoad<_StatsSnapshot>(
      () async {
        final (types, records, categoryStats) = await Parallel.wait3(
          _expenseTypeRepository.fetchForUser(userId),
          _ledgerRepository.fetchHistory(userId, limit: historyLimit),
          _statsRepository.fetchCategoryStats(userId),
        );
        return (
          monthly: buildMonthly(_clock(), records, types),
          categories: buildCategoryShares(categoryStats, types),
          recent: buildRecentExpenses(records, types),
        );
      },
      (snapshot) {
        _monthly = snapshot.monthly;
        _categories = snapshot.categories;
        _recent = snapshot.recent;
      },
      silent: silent,
    );
  }

  /// Income / expense totals for the [monthsInTrend] months ending at [today].
  static List<MonthlySummary> buildMonthly(
    DateTime today,
    List<LedgerRecord> records,
    List<ExpenseType> types,
  ) {
    final typeById = {for (final type in types) type.id: type};
    return List.generate(monthsInTrend, (index) {
      final start = DateTime(
        today.year,
        today.month - (monthsInTrend - 1) + index,
      );
      final end = DateTime(start.year, start.month + 1);
      var income = 0.0;
      var expense = 0.0;
      for (final record in records) {
        if (record.createdAt.isBefore(start) ||
            !record.createdAt.isBefore(end)) {
          continue;
        }
        final isExpense =
            record.isExpense ?? typeById[record.typeId]?.isExpense ?? true;
        if (isExpense) {
          expense += record.amount;
        } else {
          income += record.amount;
        }
      }
      return MonthlySummary(
        month: start,
        income: income,
        expense: expense,
        isCurrentMonth: index == monthsInTrend - 1,
      );
    });
  }

  static List<CategoryShare> buildCategoryShares(
    List<CategoryStat> stats,
    List<ExpenseType> types,
  ) {
    final total = stats.fold<double>(0, (sum, stat) => sum + stat.amount);
    if (total <= 0) {
      return const [];
    }
    final incomeNames = {
      for (final type in types)
        if (!type.isExpense) type.name,
    };
    return [
      for (final stat in stats)
        CategoryShare(
          category: stat.category,
          amount: stat.amount,
          percentage: (stat.amount / total).clamp(0.0, 1.0),
          isIncome: incomeNames.contains(stat.category),
        ),
    ];
  }

  /// The most recent expenses (income excluded), newest first.
  static List<RecentExpense> buildRecentExpenses(
    List<LedgerRecord> records,
    List<ExpenseType> types,
  ) {
    final typeById = {for (final type in types) type.id: type};
    return records
        .where(
          (record) =>
              record.isExpense ?? typeById[record.typeId]?.isExpense ?? true,
        )
        .take(recentExpenseCount)
        .map((record) {
          final category =
              record.typeName ?? typeById[record.typeId]?.name ?? '未分類';
          return RecentExpense(
            date: record.createdAt,
            title: record.titleOr(category),
            category: category,
            amount: record.amount,
          );
        })
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}
