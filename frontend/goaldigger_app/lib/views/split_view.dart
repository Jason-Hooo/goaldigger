part of '../main.dart';

class SplitPage extends StatelessWidget {
  const SplitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: '分帳',
      subtitle: '團體帳單與共享目標。',
      child: Column(
        children: [
          const SizedBox(height: 12),
          _MiniRow(
            items: const [
              _Pill(label: '京都旅行'),
              _Pill(label: '室友'),
              _Pill(label: '咖啡好友'),
            ],
          ),
          const SizedBox(height: 16),
          ...splitItems.map((item) => SplitTile(item: item)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.group_add_rounded),
            label: const Text('建立群組'),
          ),
        ],
      ),
    );
  }
}
