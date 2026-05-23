part of '../main.dart';

class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: '目標',
      subtitle: '用可愛存錢罐存下夢想。',
      child: Column(
        children: [
          const SizedBox(height: 12),
          ...goalItems.map((item) => GoalTile(item: item)),
          const SizedBox(height: 20),
          _SectionHeader(title: '下一步'),
          const SizedBox(height: 12),
          _ChecklistCard(
            items: const [
              '設定自動存錢',
              '新增里程碑獎勵',
              '邀請夥伴',
            ],
          ),
        ],
      ),
    );
  }
}
