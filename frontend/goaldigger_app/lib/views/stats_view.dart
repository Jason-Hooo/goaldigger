part of '../main.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key, required this.user});

  final AuthUser user;

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage>
    with RealtimeRefreshMixin<StatsPage> {
  final ApiConnect _api = ApiConnect();
  late final DateTime _today;
  List<_MonthlyData> _monthlyData = [];
  List<_CategoryData> _categoryData = [];
  List<_TransactionData> _recentTransactions = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _hasLoadedOnce = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _loadStats();
    AppRefreshBus.tick.addListener(_onAppDataChanged);
    watchTables(
      channelName: 'stats-${widget.user.userId}',
      tables: const ['personal_consumptions', 'expense_types'],
      onChange: () => _loadStats(silent: true),
    );
  }

  void _onAppDataChanged() {
    if (!mounted) {
      return;
    }
    _loadStats(silent: true);
  }

  @override
  void dispose() {
    AppRefreshBus.tick.removeListener(_onAppDataChanged);
    super.dispose();
  }

  Future<void> _loadStats({bool silent = false}) async {
    if (!silent || !_hasLoadedOnce) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else if (mounted) {
      setState(() => _isRefreshing = true);
    }

    try {
      final results = await Future.wait([
        _api.fetchExpenseTypes(widget.user.userId),
        _api.fetchLedgerHistory(widget.user.userId, limit: 300),
        _api.fetchCategoryStats(widget.user.userId),
      ]);
      final types = results[0] as List<ExpenseType>;
      final records = results[1] as List<LedgerRecord>;
      final categoryStats = results[2] as List<CategoryStat>;

      if (!mounted) {
        return;
      }

      final monthlyData = _buildMonthlyData(_today, records, types);
      final categoryData = _buildCategoryData(categoryStats, types);
      final recentTransactions = _buildRecentTransactions(records, types);

      setState(() {
        _monthlyData = monthlyData;
        _categoryData = categoryData;
        _recentTransactions = recentTransactions;
        _hasLoadedOnce = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = _readableError(error));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  String _readableError(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return '資料讀取失敗，請稍後再試。';
  }

  _MonthlyData get _currentMonth => _monthlyData.isEmpty
      ? _MonthlyData(
          month: _today,
          income: 0,
          expense: 0,
        )
      : _monthlyData.last;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _PageScaffold(
        title: '報表',
        subtitle: '查看您的收支統計與分析。',
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return _PageScaffold(
        title: '報表',
        subtitle: '查看您的收支統計與分析。',
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.pinkPrimary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!)),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _loadStats,
                    child: const Text('重試'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _PageScaffold(
      title: '報表',
      subtitle: '查看您的收支統計與分析。',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            if (_isRefreshing) const LinearProgressIndicator(minHeight: 2),
            if (_isRefreshing) const SizedBox(height: 12),
            _OverviewCard(currentMonth: _currentMonth),
            const SizedBox(height: 16),
            _CategoryBreakdownCard(categoryData: _categoryData),
            const SizedBox(height: 16),
            _MonthlyTrendCard(monthlyData: _monthlyData),
            const SizedBox(height: 16),
            _RecentTransactionsCard(transactions: _recentTransactions),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  List<_MonthlyData> _buildMonthlyData(
    DateTime today,
    List<LedgerRecord> records,
    List<ExpenseType> types,
  ) {
    final typeMap = {for (final type in types) type.id: type};
    final months = List.generate(
      6,
      (index) => DateTime(today.year, today.month - 5 + index, 1),
    );

    return months.map((month) {
      final monthStart = DateTime(month.year, month.month, 1);
      final monthEnd = DateTime(month.year, month.month + 1, 1);
      double incomeTotal = 0;
      double expenseTotal = 0;

      for (final record in records) {
        if (record.createdAt.isBefore(monthStart) ||
            !record.createdAt.isBefore(monthEnd)) {
          continue;
        }

        final type = typeMap[record.typeId];
        final isExpense = record.isExpense ?? type?.isExpense ?? true;

        if (isExpense) {
          expenseTotal += record.amount;
        } else {
          incomeTotal += record.amount;
        }
      }

      return _MonthlyData(
        month: month,
        income: incomeTotal,
        expense: expenseTotal,
      );
    }).toList();
  }

  List<_CategoryData> _buildCategoryData(List<CategoryStat> stats, List<ExpenseType> types) {
    final incomeTypeNames = types.where((t) => !t.isExpense).map((t) => t.name).toSet();

    final total = stats.fold<double>(0, (sum, item) => sum + item.amount);
    if (total <= 0) {
      return const [];
    }

    return stats
        .map(
          (item) => _CategoryData(
            category: item.category,
            amount: item.amount,
            percentage: (item.amount / total).clamp(0.0, 1.0),
            isIncome: incomeTypeNames.contains(item.category),
          ),
        )
        .toList();
  }

  List<_TransactionData> _buildRecentTransactions(
    List<LedgerRecord> records,
    List<ExpenseType> types,
  ) {
    final typeMap = {for (final type in types) type.id: type};

    return records
        .where((record) => record.isExpense ?? typeMap[record.typeId]?.isExpense ?? true)
        .take(10)
        .map((record) {
          final type = typeMap[record.typeId];
          final typeName = record.typeName ?? type?.name ?? '未分類';
          final description = (record.description ?? '').trim();
          final parts = description.split(' · ');
          final title = parts.firstWhere(
            (part) => part.isNotEmpty,
            orElse: () => typeName,
          );

          return _TransactionData(
            date: record.createdAt,
            title: title,
            category: typeName,
            amount: record.amount,
          );
        })
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.currentMonth});

  final _MonthlyData currentMonth;

  @override
  Widget build(BuildContext context) {
    final balance = currentMonth.income - currentMonth.expense;
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
                Text(
                  '本月概覽',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${currentMonth.month.year}/${currentMonth.month.month.toString().padLeft(2, '0')}',
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
                  value: currentMonth.income,
                  color: AppColors.green,
                ),
                _StatItem(
                  label: '支出',
                  value: currentMonth.expense,
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

class _CategoryBreakdownCard extends StatelessWidget {
  const _CategoryBreakdownCard({required this.categoryData});

  final List<_CategoryData> categoryData;

  @override
  Widget build(BuildContext context) {
    if (categoryData.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: const [
              Icon(Icons.pie_chart, color: AppColors.inkLight),
              SizedBox(width: 12),
              Expanded(child: Text('尚無支出資料')),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '收入/支出分類',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...categoryData.map(
              (data) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CategoryBar(data: data),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.data});

  final _CategoryData data;

  @override
  Widget build(BuildContext context) {

    final barColor = data.isIncome ? AppColors.green : AppColors.pinkPrimary;
    final bgColor = data.isIncome ? AppColors.green.withValues(alpha: 0.15) : AppColors.pinkSoft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(data.category),
            Text(
              '\$${_formatStatsMoney(data.amount)} (${(data.percentage * 100).toStringAsFixed(0)}%)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: data.percentage,
           backgroundColor: bgColor,
           valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _MonthlyTrendCard extends StatelessWidget {
  const _MonthlyTrendCard({required this.monthlyData});

  final List<_MonthlyData> monthlyData;

  @override
  Widget build(BuildContext context) {
    final maxExpense = monthlyData.fold<double>(
      0,
      (max, data) => data.expense > max ? data.expense : max,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '近六個月支出',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: monthlyData
                    .map(
                      (data) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '\$${_formatStatsMoney(data.expense)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 100,
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  width: 24,
                                  height: maxExpense <= 0
                                      ? 0
                                      : 100 * (data.expense / maxExpense),
                                  decoration: BoxDecoration(
                                    color: data.isCurrentMonth
                                        ? AppColors.pinkPrimary
                                        : AppColors.pinkSoft,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${data.month.month}月',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTransactionsCard extends StatelessWidget {
  const _RecentTransactionsCard({required this.transactions});

  final List<_TransactionData> transactions;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: const [
              Icon(Icons.receipt_long, color: AppColors.inkLight),
              SizedBox(width: 12),
              Expanded(child: Text('尚無支出紀錄')),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '最近支出',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...transactions.map(
              (transaction) => _TransactionTile(transaction: transaction),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final _TransactionData transaction;

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
              '${transaction.date.day}',
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
                  transaction.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${_formatDate(transaction.date)} · ${transaction.category}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.inkLight,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '-\$${_formatStatsMoney(transaction.amount)}',
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
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.inkLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isNegative ? '-\$${_formatStatsMoney(value)}' : '\$${_formatStatsMoney(value)}',
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

class _MonthlyData {
  const _MonthlyData({
    required this.month,
    required this.income,
    required this.expense,
  });

  final DateTime month;
  final double income;
  final double expense;

  bool get isCurrentMonth =>
      month.year == DateTime.now().year && month.month == DateTime.now().month;
}

class _CategoryData {
  const _CategoryData({
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

class _TransactionData {
  const _TransactionData({
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

String _formatStatsMoney(double value) {
  final fixed = value.toStringAsFixed(0);
  return fixed.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
}

String _formatDate(DateTime date) {
  return '${date.month}/${date.day}';
}
