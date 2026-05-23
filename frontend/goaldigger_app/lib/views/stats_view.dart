part of '../main.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: '報表',
      subtitle: '簡單圖表與洞察。',
      child: Column(
        children: [
          const SizedBox(height: 12),
          _ChartCard(
            title: '支出比例',
            data: const [
              _ChartSlice(label: '餐飲', value: 0.35),
              _ChartSlice(label: '旅行', value: 0.25),
              _ChartSlice(label: '購物', value: 0.18),
              _ChartSlice(label: '帳單', value: 0.22),
            ],
          ),
          const SizedBox(height: 16),
          _ChartCard(
            title: '目標進度',
            data: const [
              _ChartSlice(label: '相機', value: 0.6),
              _ChartSlice(label: '健身', value: 0.42),
              _ChartSlice(label: '旅行', value: 0.8),
            ],
          ),
        ],
      ),
    );
  }
}
