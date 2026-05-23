part of '../main.dart';

class LedgerPage extends StatelessWidget {
  const LedgerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: '記帳',
      subtitle: '收入與支出快速整理。',
      child: Column(
        children: [
          const SizedBox(height: 12),
          _BalanceCard(balance: 2480.25, income: 3200.0, expense: 719.75),
          const SizedBox(height: 20),
          _SectionHeader(title: '最新紀錄'),
          const SizedBox(height: 12),
          ...ledgerItems.map((item) => LedgerTile(item: item)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('新增紀錄'),
          ),
        ],
      ),
    );
  }
}
