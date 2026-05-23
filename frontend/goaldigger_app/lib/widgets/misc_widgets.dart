part of '../main.dart';

class _MiniRow extends StatelessWidget {
  const _MiniRow({required this.items});

  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 10, runSpacing: 10, children: items);
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.pinkSoft),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        Text(
              '示範',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: AppColors.pinkPrimary),
        ),
      ],
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.pinkPrimary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(item)),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
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
            Text(
              '本月結餘',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '\$${balance.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatChip(
                  label: '收入',
                  value: income,
                  color: AppColors.green,
                ),
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
          color: color.withOpacity(0.12),
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
  const LedgerTile({super.key, required this.item});

  final LedgerItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
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
  const GoalTile({super.key, required this.item});

  final GoalItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.title, style: Theme.of(context).textTheme.titleLarge),
                Text('${(item.progress * 100).toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: item.progress,
                minHeight: 10,
                backgroundColor: AppColors.pinkSoft,
                valueColor: const AlwaysStoppedAnimation(AppColors.pinkPrimary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.subtitle,
              style: const TextStyle(color: AppColors.inkLight),
            ),
          ],
        ),
      ),
    );
  }
}

class SplitTile extends StatelessWidget {
  const SplitTile({super.key, required this.item});

  final SplitItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
