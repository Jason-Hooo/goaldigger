part of '../main.dart';



 

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.income,
    required this.expense,
  });

  final double balance;
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('本月結餘', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '\$${balance.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatChip(label: '收入', value: income, color: AppColors.green),
                const SizedBox(width: 12),
                _StatChip(
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

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('\$${value.toStringAsFixed(0)}'),
          ],
        ),
      ),
    );
  }
}

class LedgerTile extends StatelessWidget {
  const LedgerTile({super.key, required this.item, this.onTap});

  final LedgerItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.pinkSoft,
          child: Icon(item.icon, color: AppColors.pinkPrimary),
        ),
        title: Text(item.title),
        subtitle: Text(item.subtitle),
        trailing: Text(
          item.amount,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: item.isIncome ? AppColors.green : AppColors.pinkPrimary,
          ),
        ),
      ),
    );
  }
}

class GoalTile extends StatelessWidget {
  const GoalTile({super.key, required this.item, this.onTap});

  final GoalItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: const TextStyle(color: AppColors.inkLight),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.progressLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.pinkPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.deadlineLabel,
                        style: const TextStyle(color: AppColors.inkLight),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: item.progress,
                  minHeight: 10,
                  backgroundColor: AppColors.pinkSoft,
                  valueColor: const AlwaysStoppedAnimation(
                    AppColors.pinkPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text('已存 ${item.savedAmountLabel}'),
                  const Spacer(),
                  Text('目標 ${item.targetAmountLabel}'),
                  const SizedBox(width: 12),
                  Text('還差 ${item.remainingAmountLabel}'),
                ],
              ),
              if (item.isAchieved) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '已達成',
                    style: TextStyle(
                      color: AppColors.green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SplitTile extends StatelessWidget {
  const SplitTile({super.key, required this.item, this.onTap});

  final SplitItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.pinkSoft,
            child: Icon(item.icon, color: AppColors.pinkPrimary),
          ),
          title: Text(item.title),
          subtitle: Text(item.subtitle),
          trailing: Text(
            item.amount,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.data});

  final String title;
  final List<_ChartSlice> data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Column(
              children: data
                  .map(
                    (slice) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: slice.value,
                                minHeight: 10,
                                backgroundColor: AppColors.pinkSoft,
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.pinkPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 86,
                            child: Text(
                              '${slice.label} ${(slice.value * 100).toStringAsFixed(0)}%',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartSlice {
  const _ChartSlice({required this.label, required this.value});

  final String label;
  final double value;
}
