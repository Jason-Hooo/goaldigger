import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/page_scaffold.dart';
import '../view_models/stats_view_model.dart';
import '../widgets/stats_cards.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<StatsViewModel>();
    final errorMessage = viewModel.errorMessage;

    final Widget content;
    if (viewModel.isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (errorMessage != null) {
      content = ErrorStateCard(message: errorMessage, onRetry: viewModel.load);
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          if (viewModel.isRefreshing) ...[
            const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 12),
          ],
          OverviewCard(month: viewModel.currentMonth),
          const SizedBox(height: 16),
          CategoryBreakdownCard(shares: viewModel.categories),
          const SizedBox(height: 16),
          MonthlyTrendCard(months: viewModel.monthly),
          const SizedBox(height: 16),
          RecentExpensesCard(expenses: viewModel.recentExpenses),
          const SizedBox(height: 20),
        ],
      );
    }

    return PageScaffold(
      title: '報表',
      subtitle: '查看您的收支統計與分析。',
      child: content,
    );
  }
}
