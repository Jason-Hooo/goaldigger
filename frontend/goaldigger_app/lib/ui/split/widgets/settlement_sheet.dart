import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/sheets.dart';
import '../view_models/settlement_view_model.dart';

/// Suggested transfers for a group, backed by [SettlementViewModel].
class SettlementSheet extends StatelessWidget {
  const SettlementSheet({super.key, required this.groupName});

  final String groupName;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettlementViewModel>();
    final errorMessage = viewModel.errorMessage;

    return SheetBody(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$groupName 結算建議',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            '根據目前的分帳紀錄，建議的結算方式如下：',
            style: TextStyle(color: AppColors.inkLight),
          ),
          const SizedBox(height: 16),
          if (viewModel.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (errorMessage != null)
            Card(
              color: AppColors.pinkSoft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(errorMessage),
              ),
            )
          else if (viewModel.settlements.isEmpty)
            InlineBanner(
              message: '所有帳款已結算完成！',
              icon: Icons.check_circle,
              color: AppColors.green,
              background: AppColors.green.withValues(alpha: 0.1),
            )
          else
            for (final settlement in viewModel.settlements)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.pinkPrimary.withValues(
                      alpha: 0.15,
                    ),
                    child: const Icon(
                      Icons.swap_horiz,
                      color: AppColors.pinkPrimary,
                    ),
                  ),
                  title: Text('${settlement.fromName} → ${settlement.toName}'),
                  subtitle: Text(
                    '轉帳 \$${Formatters.amount(settlement.amount)}',
                  ),
                  trailing: Text(
                    '\$${Formatters.amount(settlement.amount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.pinkPrimary,
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: viewModel.load,
              icon: const Icon(Icons.refresh),
              label: const Text('重新計算'),
            ),
          ),
        ],
      ),
    );
  }
}
