part of '../main.dart';

enum _ReviewRange { week, month, year }

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  late final DateTime _today;
  late final List<_MonthlySnapshot> _monthlySnapshots;
  late final List<_ExpenseRecord> _expenseRecords;

  _ReviewRange _reviewRange = _ReviewRange.month;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _monthlySnapshots = _buildMonthlySnapshots(_today);
    _expenseRecords = _buildExpenseRecords(_today);
  }

  _MonthlySnapshot get _currentMonth => _monthlySnapshots.last;

  DateTime? get _latestLedgerDate {
    final dates = ledgerItems
        .map((item) => item.recordedAt)
        .whereType<DateTime>()
        .toList();
    if (dates.isEmpty) {
      return null;
    }
    return dates.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  int? get _daysSinceLastLedger {
    final latest = _latestLedgerDate;
    if (latest == null) {
      return null;
    }
    return DateUtils.dateOnly(
      _today,
    ).difference(DateUtils.dateOnly(latest)).inDays;
  }

  List<GoalItem> get _atRiskGoals {
    return goalItems
        .where(
          (goal) =>
              !goal.isAchieved &&
              _daysUntil(goal.deadline, _today) <= 30 &&
              _daysUntil(goal.deadline, _today) >= 0,
        )
        .toList();
  }

  List<_ExpenseRecord> get _reviewRecords {
    final filtered =
        _expenseRecords
            .where((record) => _isWithinReviewRange(record.date))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final reviewRecords = _reviewRecords;

    return _PageScaffold(
      title: '報表',
      subtitle: '月收入、固定支出、損益與週月年支出回顧。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _MonthlyIncomeSummaryCard(snapshot: _currentMonth),
          const SizedBox(height: 20),
          _ReminderCenterCard(
            daysSinceLastLedger: _daysSinceLastLedger,
            atRiskGoals: _atRiskGoals,
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: '支出變化'),
          const SizedBox(height: 12),
          _MonthlyExpenseBarChart(snapshots: _monthlySnapshots),
          const SizedBox(height: 16),
          _SectionHeader(title: '當月損益與占比'),
          const SizedBox(height: 12),
          _ProfitLossCard(snapshot: _currentMonth),
          const SizedBox(height: 12),
          _ChartCard(title: '不同種類支出占比', data: _currentMonth.expenseShares),
          const SizedBox(height: 20),
          _SectionHeader(title: '支出回顧'),
          const SizedBox(height: 12),
          _ReviewRangeSelector(
            selectedRange: _reviewRange,
            onChanged: (range) => setState(() => _reviewRange = range),
          ),
          const SizedBox(height: 12),
          _ReviewSummaryCard(range: _reviewRange, records: reviewRecords),
          const SizedBox(height: 12),
          if (reviewRecords.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: const [
                    Icon(Icons.receipt_long, color: AppColors.inkLight),
                    SizedBox(width: 12),
                    Expanded(child: Text('這段時間沒有支出紀錄。')),
                  ],
                ),
              ),
            )
          else
            ...reviewRecords.map(
              (record) => _ExpenseRecordTile(record: record),
            ),
        ],
      ),
    );
  }

  bool _isWithinReviewRange(DateTime date) {
    final normalizedDate = DateUtils.dateOnly(date);
    final today = DateUtils.dateOnly(_today);

    return switch (_reviewRange) {
      _ReviewRange.week => !normalizedDate.isBefore(
        today.subtract(const Duration(days: 6)),
      ),
      _ReviewRange.month =>
        normalizedDate.year == today.year &&
            normalizedDate.month == today.month,
      _ReviewRange.year => normalizedDate.year == today.year,
    };
  }

  List<_MonthlySnapshot> _buildMonthlySnapshots(DateTime today) {
    const incomes = [48600.0, 49800.0, 51200.0, 53000.0, 54800.0, 56600.0];
    const fixedExpenses = [
      16800.0,
      17050.0,
      17200.0,
      17450.0,
      17600.0,
      17800.0,
    ];

    const variableBuckets = [
      [
        _ExpenseBucket(label: '餐飲', amount: 6200),
        _ExpenseBucket(label: '交通', amount: 1800),
        _ExpenseBucket(label: '購物', amount: 2600),
        _ExpenseBucket(label: '娛樂', amount: 1400),
      ],
      [
        _ExpenseBucket(label: '餐飲', amount: 6100),
        _ExpenseBucket(label: '交通', amount: 1900),
        _ExpenseBucket(label: '購物', amount: 2800),
        _ExpenseBucket(label: '娛樂', amount: 1500),
      ],
      [
        _ExpenseBucket(label: '餐飲', amount: 5900),
        _ExpenseBucket(label: '交通', amount: 2000),
        _ExpenseBucket(label: '購物', amount: 3000),
        _ExpenseBucket(label: '娛樂', amount: 1600),
      ],
      [
        _ExpenseBucket(label: '餐飲', amount: 6400),
        _ExpenseBucket(label: '交通', amount: 2100),
        _ExpenseBucket(label: '購物', amount: 3100),
        _ExpenseBucket(label: '娛樂', amount: 1700),
      ],
      [
        _ExpenseBucket(label: '餐飲', amount: 6600),
        _ExpenseBucket(label: '交通', amount: 2200),
        _ExpenseBucket(label: '購物', amount: 3200),
        _ExpenseBucket(label: '娛樂', amount: 1800),
      ],
      [
        _ExpenseBucket(label: '餐飲', amount: 6800),
        _ExpenseBucket(label: '交通', amount: 2300),
        _ExpenseBucket(label: '購物', amount: 3300),
        _ExpenseBucket(label: '娛樂', amount: 1900),
      ],
    ];

    return List.generate(6, (index) {
      final month = DateTime(today.year, today.month - 5 + index, 1);
      return _MonthlySnapshot(
        month: month,
        income: incomes[index],
        fixedExpense: fixedExpenses[index],
        variableBuckets: variableBuckets[index],
      );
    });
  }

  List<_ExpenseRecord> _buildExpenseRecords(DateTime today) {
    final base = DateTime(today.year, today.month, today.day);
    return [
      _ExpenseRecord(
        date: base.subtract(const Duration(days: 1)),
        title: '便利商店早餐',
        category: '餐飲',
        amount: 118,
        note: '咖啡 + 三明治',
      ),
      _ExpenseRecord(
        date: base.subtract(const Duration(days: 2)),
        title: '捷運通勤',
        category: '交通',
        amount: 75,
        note: '上下班交通',
      ),
      _ExpenseRecord(
        date: base.subtract(const Duration(days: 4)),
        title: '午餐聚會',
        category: '餐飲',
        amount: 260,
        note: '同事聚餐',
      ),
      _ExpenseRecord(
        date: base.subtract(const Duration(days: 6)),
        title: '超商補貨',
        category: '購物',
        amount: 240,
        note: '生活用品',
      ),
      _ExpenseRecord(
        date: base.subtract(const Duration(days: 9)),
        title: '手機月租',
        category: '固定支出',
        amount: 399,
        note: '每月固定費用',
      ),
      _ExpenseRecord(
        date: base.subtract(const Duration(days: 12)),
        title: '晚餐外帶',
        category: '餐飲',
        amount: 210,
        note: '加班晚餐',
      ),
      _ExpenseRecord(
        date: base.subtract(const Duration(days: 16)),
        title: '串流訂閱',
        category: '固定支出',
        amount: 320,
        note: '娛樂訂閱',
      ),
      _ExpenseRecord(
        date: base.subtract(const Duration(days: 21)),
        title: '咖啡豆',
        category: '購物',
        amount: 480,
        note: '家用補給',
      ),
      _ExpenseRecord(
        date: base.subtract(const Duration(days: 31)),
        title: '週末電影',
        category: '娛樂',
        amount: 520,
        note: '兩張票 + 爆米花',
      ),
      _ExpenseRecord(
        date: base.subtract(const Duration(days: 40)),
        title: '手機配件',
        category: '購物',
        amount: 780,
        note: '充電線與保護殼',
      ),
      _ExpenseRecord(
        date: base.subtract(const Duration(days: 52)),
        title: '外食午餐',
        category: '餐飲',
        amount: 180,
      ),
      _ExpenseRecord(
        date: base.subtract(const Duration(days: 64)),
        title: '停車費',
        category: '交通',
        amount: 120,
      ),
      _ExpenseRecord(
        date: base.subtract(const Duration(days: 78)),
        title: '日用品採買',
        category: '購物',
        amount: 560,
      ),
      _ExpenseRecord(
        date: base.subtract(const Duration(days: 94)),
        title: '年度保險分期',
        category: '固定支出',
        amount: 1800,
        note: '保險費用',
      ),
      _ExpenseRecord(
        date: base.subtract(const Duration(days: 118)),
        title: '朋友聚餐',
        category: '餐飲',
        amount: 680,
      ),
      _ExpenseRecord(
        date: base.subtract(const Duration(days: 145)),
        title: '旅遊交通',
        category: '交通',
        amount: 1420,
        note: '高鐵 + 接駁',
      ),
    ];
  }
}

class _MonthlyIncomeSummaryCard extends StatelessWidget {
  const _MonthlyIncomeSummaryCard({required this.snapshot});

  final _MonthlySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final disposableRatio = snapshot.income <= 0
        ? 0.0
        : (snapshot.availableAfterFixed / snapshot.income).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('月收入與固定支出', style: Theme.of(context).textTheme.titleLarge),
                Text(
                  snapshot.monthLabel,
                  style: const TextStyle(color: AppColors.inkLight),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '平均每日可支配所得：\$${_formatStatsMoney(snapshot.averageDailyDisposable)}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatChip(
                  label: '月收入',
                  value: snapshot.income,
                  color: AppColors.green,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  label: '固定支出',
                  value: snapshot.fixedExpense,
                  color: AppColors.pinkPrimary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '固定支出占收入 ${(disposableRatio * 100).toStringAsFixed(0)}% 可支配',
              style: const TextStyle(color: AppColors.inkLight),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderCenterCard extends StatelessWidget {
  const _ReminderCenterCard({
    required this.daysSinceLastLedger,
    required this.atRiskGoals,
  });

  final int? daysSinceLastLedger;
  final List<GoalItem> atRiskGoals;

  @override
  Widget build(BuildContext context) {
    final reminders = <_ReminderEntry>[];

    if (daysSinceLastLedger != null && daysSinceLastLedger! >= 3) {
      reminders.add(
        _ReminderEntry(
          title: '記帳提醒',
          message: '已經 ${daysSinceLastLedger!} 天沒有新增記帳，建議今天補登。',
          icon: Icons.receipt_long,
          color: AppColors.pinkPrimary,
        ),
      );
    }

    for (final goal in atRiskGoals) {
      reminders.add(
        _ReminderEntry(
          title: '目標進度提醒',
          message:
              '${goal.title} 距離期限剩 ${_daysUntil(goal.deadline, DateTime.now())} 天，請留意存款進度。',
          icon: Icons.flag_rounded,
          color: AppColors.green,
        ),
      );
    }

    if (reminders.isEmpty) {
      reminders.add(
        _ReminderEntry(
          title: '提醒狀態正常',
          message: '最近有正常記帳，暫時沒有高風險目標。',
          icon: Icons.check_circle,
          color: AppColors.green,
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('提醒中心', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...reminders.map(
              (reminder) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: reminder.color.withValues(alpha: 0.12),
                      child: Icon(
                        reminder.icon,
                        color: reminder.color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reminder.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            reminder.message,
                            style: const TextStyle(color: AppColors.inkLight),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyExpenseBarChart extends StatelessWidget {
  const _MonthlyExpenseBarChart({required this.snapshots});

  final List<_MonthlySnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    final maxValue = snapshots.fold<double>(
      0,
      (max, snapshot) =>
          snapshot.totalExpense > max ? snapshot.totalExpense : max,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('近六個月支出長條圖', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 18),
            SizedBox(
              height: 220,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: snapshots
                    .map(
                      (snapshot) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '\$${_formatStatsMoney(snapshot.totalExpense)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                height: 132,
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  width: 20,
                                  height: maxValue <= 0
                                      ? 0
                                      : 132 *
                                            (snapshot.totalExpense / maxValue),
                                  decoration: BoxDecoration(
                                    color: snapshot.isCurrentMonth
                                        ? AppColors.pinkPrimary
                                        : AppColors.pinkSoft,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(snapshot.monthLabel),
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

class _ProfitLossCard extends StatelessWidget {
  const _ProfitLossCard({required this.snapshot});

  final _MonthlySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final isPositive = snapshot.balance >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('當月損益', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              isPositive
                  ? '盈餘 \$${_formatStatsMoney(snapshot.balance)}'
                  : '赤字 \$${_formatStatsMoney(snapshot.balance.abs())}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: isPositive ? AppColors.green : AppColors.pinkPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatChip(
                  label: '收入',
                  value: snapshot.income,
                  color: AppColors.green,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  label: '總支出',
                  value: snapshot.totalExpense,
                  color: AppColors.pinkPrimary,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  label: '固定',
                  value: snapshot.fixedExpense,
                  color: AppColors.inkLight,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '變動支出 \$${_formatStatsMoney(snapshot.variableExpense)}，剩餘可支配 \$${_formatStatsMoney(snapshot.availableAfterFixed)}',
              style: const TextStyle(color: AppColors.inkLight),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewRangeSelector extends StatelessWidget {
  const _ReviewRangeSelector({
    required this.selectedRange,
    required this.onChanged,
  });

  final _ReviewRange selectedRange;
  final ValueChanged<_ReviewRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _RangeChip(
          label: '週',
          selected: selectedRange == _ReviewRange.week,
          onTap: () => onChanged(_ReviewRange.week),
        ),
        _RangeChip(
          label: '月',
          selected: selectedRange == _ReviewRange.month,
          onTap: () => onChanged(_ReviewRange.month),
        ),
        _RangeChip(
          label: '年',
          selected: selectedRange == _ReviewRange.year,
          onTap: () => onChanged(_ReviewRange.year),
        ),
      ],
    );
  }
}

class _ReviewSummaryCard extends StatelessWidget {
  const _ReviewSummaryCard({required this.range, required this.records});

  final _ReviewRange range;
  final List<_ExpenseRecord> records;

  @override
  Widget build(BuildContext context) {
    final total = records.fold<double>(0, (sum, record) => sum + record.amount);
    final average = records.isEmpty ? 0.0 : total / records.length;
    final categoryTotals = <String, double>{};
    for (final record in records) {
      categoryTotals[record.category] =
          (categoryTotals[record.category] ?? 0.0) + record.amount;
    }
    final topCategory = categoryTotals.entries.isEmpty
        ? '無'
        : categoryTotals.entries
              .reduce((a, b) => a.value >= b.value ? a : b)
              .key;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${range.label}支出回顧',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '共 ${records.length} 筆・總支出 \$${_formatStatsMoney(total)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatChip(
                  label: '平均單筆',
                  value: average,
                  color: AppColors.green,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  label: '最高分類',
                  value: records.isEmpty
                      ? 0.0
                      : categoryTotals[topCategory] ?? 0.0,
                  color: AppColors.pinkPrimary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '最高分類：$topCategory',
              style: const TextStyle(color: AppColors.inkLight),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseRecordTile extends StatelessWidget {
  const _ExpenseRecordTile({required this.record});

  final _ExpenseRecord record;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: record.category == '固定支出'
              ? AppColors.inkLight.withValues(alpha: 0.16)
              : AppColors.pinkSoft,
          child: Text(
            '${record.date.day}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: record.category == '固定支出'
                  ? AppColors.inkLight
                  : AppColors.pinkPrimary,
            ),
          ),
        ),
        title: Text(record.title),
        subtitle: Text(
          '${_formatDate(record.date)} · ${record.category}${record.note == null ? '' : ' · ${record.note}'}',
        ),
        trailing: Text(
          '-\$${_formatStatsMoney(record.amount)}',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.pinkPrimary,
          ),
        ),
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.pinkSoft,
      labelStyle: TextStyle(
        color: selected ? AppColors.pinkPrimary : AppColors.ink,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _MonthlySnapshot {
  const _MonthlySnapshot({
    required this.month,
    required this.income,
    required this.fixedExpense,
    required this.variableBuckets,
  });

  final DateTime month;
  final double income;
  final double fixedExpense;
  final List<_ExpenseBucket> variableBuckets;

  bool get isCurrentMonth =>
      month.year == DateTime.now().year && month.month == DateTime.now().month;

  String get monthLabel => '${month.month}月';

  double get variableExpense =>
      variableBuckets.fold<double>(0, (sum, bucket) => sum + bucket.amount);

  double get totalExpense => fixedExpense + variableExpense;

  double get balance => income - totalExpense;

  double get availableAfterFixed => income - fixedExpense;

  int get daysInMonth => DateUtils.getDaysInMonth(month.year, month.month);

  double get averageDailyDisposable => availableAfterFixed / daysInMonth;

  List<_ChartSlice> get expenseShares {
    final total = totalExpense <= 0 ? 1 : totalExpense;
    return [
      _ChartSlice(label: '固定支出', value: fixedExpense / total),
      ...variableBuckets.map(
        (bucket) =>
            _ChartSlice(label: bucket.label, value: bucket.amount / total),
      ),
    ];
  }
}

class _ExpenseBucket {
  const _ExpenseBucket({required this.label, required this.amount});

  final String label;
  final double amount;
}

class _ReminderEntry {
  const _ReminderEntry({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;
}

class _ExpenseRecord {
  const _ExpenseRecord({
    required this.date,
    required this.title,
    required this.category,
    required this.amount,
    this.note,
  });

  final DateTime date;
  final String title;
  final String category;
  final double amount;
  final String? note;
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

int _daysUntil(DateTime date, DateTime today) {
  return DateUtils.dateOnly(date).difference(DateUtils.dateOnly(today)).inDays;
}

extension on _ReviewRange {
  String get label {
    return switch (this) {
      _ReviewRange.week => '週',
      _ReviewRange.month => '月',
      _ReviewRange.year => '年',
    };
  }
}
