import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/result/result.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/sheets.dart';
import '../view_models/ledger_entry.dart';
import '../view_models/ledger_view_model.dart';
import '../widgets/ledger_detail_sheet.dart';
import '../widgets/ledger_entry_sheet.dart';
import '../widgets/ledger_widgets.dart';

class LedgerScreen extends StatelessWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LedgerViewModel>();
    final errorMessage = viewModel.errorMessage;

    return SizedBox.expand(
      child: Stack(
        children: [
          PageScaffold(
            title: '記帳',
            subtitle: '收入與支出快速整理。',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                BalanceCard(
                  balance: viewModel.balance,
                  income: viewModel.incomeTotal,
                  expense: viewModel.expenseTotal,
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: '最新紀錄'),
                const SizedBox(height: 12),
                if (viewModel.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (errorMessage != null)
                  ErrorStateCard(message: errorMessage, onRetry: viewModel.load)
                else if (viewModel.entries.isEmpty)
                  const EmptyStateCard(
                    icon: Icons.receipt_long,
                    message: '目前沒有記帳紀錄。',
                  )
                else ...[
                  if (viewModel.isRefreshing)
                    const LinearProgressIndicator(minHeight: 2),
                  for (final entry in viewModel.entries)
                    LedgerTile(
                      entry: entry,
                      onTap: () => _openDetail(context, entry),
                    ),
                ],
              ],
            ),
          ),
          PageFab(
            heroTag: 'fab-ledger',
            onPressed: () => _openEntrySheet(context, LedgerEntryMode.create),
          ),
        ],
      ),
    );
  }

  Future<void> _openDetail(BuildContext context, LedgerEntry entry) async {
    final action = await showAppBottomSheet<LedgerDetailAction>(
      context,
      builder: (_) => LedgerDetailSheet(entry: entry),
    );
    if (action == null || !context.mounted) {
      return;
    }
    switch (action) {
      case LedgerDetailAction.edit:
        await _openEntrySheet(context, LedgerEntryMode.edit, entry);
      case LedgerDetailAction.duplicate:
        await _openEntrySheet(context, LedgerEntryMode.duplicate, entry);
      case LedgerDetailAction.delete:
        await _delete(context, entry);
    }
  }

  Future<void> _openEntrySheet(
    BuildContext context,
    LedgerEntryMode mode, [
    LedgerEntry? initialEntry,
  ]) async {
    final viewModel = context.read<LedgerViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    if (!viewModel.canCreateEntry) {
      messenger.showMessage('尚未取得分類資料，請稍後再試。');
      return;
    }

    final draft = await showAppBottomSheet<LedgerDraft>(
      context,
      builder: (_) => LedgerEntrySheet(
        expenseTypes: viewModel.expenseTypes,
        goals: viewModel.goals,
        mode: mode,
        initialEntry: initialEntry,
      ),
    );
    if (draft == null) {
      return;
    }

    final result = await viewModel.save(draft);
    final kind = draft.isIncome ? '收入' : '支出';
    messenger.showMessage(switch (result) {
      Success() when draft.isNew => '已新增$kind：${draft.title}',
      Success() => '已更新$kind：${draft.title}',
      Failure(:final message) => message,
    });
  }

  Future<void> _delete(BuildContext context, LedgerEntry entry) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await context.read<LedgerViewModel>().delete(entry);
    messenger.showMessage(switch (result) {
      Success() => '已刪除 ${entry.title}',
      Failure(:final message) => message,
    });
  }
}
