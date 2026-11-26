import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/result/result.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/split.dart';
import '../../../data/repositories/expense_type/expense_type_repository.dart';
import '../../../data/repositories/split/split_repository.dart';
import '../../../data/services/realtime/realtime_service.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/sheets.dart';
import '../view_models/group_detail_view_model.dart';
import '../view_models/group_expense_editor_view_model.dart';
import '../view_models/settlement_view_model.dart';
import '../widgets/expense_detail_sheet.dart';
import '../widgets/group_expense_editor_sheet.dart';
import '../widgets/group_info_sheets.dart';
import '../widgets/settlement_sheet.dart';
import '../widgets/split_widgets.dart';

class GroupDetailScreen extends StatelessWidget {
  const GroupDetailScreen({super.key});

  /// Builds the screen together with its scoped [GroupDetailViewModel].
  static Widget route({required GroupSummary group, required int userId}) {
    return ChangeNotifierProvider(
      create: (context) => GroupDetailViewModel(
        userId: userId,
        group: group,
        splitRepository: context.read<SplitRepository>(),
        realtime: context.read<RealtimeService>(),
      )..init(),
      child: const GroupDetailScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GroupDetailViewModel>();
    final group = viewModel.group;
    final errorMessage = viewModel.errorMessage;

    return Scaffold(
      appBar: AppBar(
        title: Text(group.groupName),
        backgroundColor: AppColors.pinkPrimary,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.people),
              tooltip: '群組成員',
              onPressed: () => showAppBottomSheet<void>(
                context,
                showDragHandle: false,
                builder: (_) => MembersSheet(members: viewModel.members),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          GroupActionTile(
            icon: Icons.qr_code,
            title: '分享邀請碼',
            subtitle: '顯示 QR Code 讓其他人掃描加入',
            onTap: () => showAppBottomSheet<void>(
              context,
              showDragHandle: false,
              builder: (_) =>
                  InvitationQrSheet(invitationCode: group.invitationCode),
            ),
          ),
          const SizedBox(height: 16),
          GroupActionTile(
            icon: Icons.exit_to_app,
            title: '退出群組',
            subtitle: '離開此群組',
            color: Colors.red,
            onTap: () => _confirmLeave(context),
          ),
          const SizedBox(height: 16),
          GroupActionTile(
            icon: Icons.account_balance_wallet,
            title: '結算建議',
            subtitle: '查看誰該轉帳給誰',
            onTap: () => _openSettlement(context),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: PageScaffold(
              title: '群組帳目',
              subtitle: '此群組的分帳紀錄',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  if (viewModel.isRefreshing) ...[
                    const LinearProgressIndicator(minHeight: 2),
                    const SizedBox(height: 12),
                  ],
                  if (viewModel.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (errorMessage != null)
                    ErrorStateCard(
                      message: errorMessage,
                      onRetry: viewModel.load,
                    )
                  else if (viewModel.expenses.isEmpty)
                    const EmptyStateCard(
                      icon: Icons.receipt_long,
                      message: '還沒有帳目紀錄，按右下角新增一筆。',
                    )
                  else
                    for (final expense in viewModel.expenses)
                      GroupExpenseTile(
                        expense: expense,
                        currentUserId: viewModel.userId,
                        onTap: () => _openExpenseDetail(context, expense),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-split',
        onPressed: () => _openExpenseEditor(context),
        backgroundColor: AppColors.pinkPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openExpenseDetail(
    BuildContext context,
    SplitExpense expense,
  ) async {
    final viewModel = context.read<GroupDetailViewModel>();
    final action = await showAppBottomSheet<ExpenseDetailAction>(
      context,
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: ExpenseDetailSheet(initialExpense: expense),
      ),
    );
    if (action == null || !context.mounted) {
      return;
    }
    final latest = viewModel.expenseById(expense.consumptionId) ?? expense;
    switch (action) {
      case ExpenseDetailAction.edit:
        await _openExpenseEditor(context, latest);
      case ExpenseDetailAction.delete:
        await _confirmDelete(context, latest);
    }
  }

  Future<void> _openExpenseEditor(
    BuildContext context, [
    SplitExpense? initialExpense,
  ]) async {
    final viewModel = context.read<GroupDetailViewModel>();
    final request = await showAppBottomSheet<SplitExpenseRequest>(
      context,
      builder: (sheetContext) => ChangeNotifierProvider(
        create: (_) => GroupExpenseEditorViewModel(
          userId: viewModel.userId,
          group: viewModel.group,
          initialExpense: initialExpense,
          splitRepository: context.read<SplitRepository>(),
          expenseTypeRepository: context.read<ExpenseTypeRepository>(),
        )..init(),
        child: const GroupExpenseEditorSheet(),
      ),
    );
    if (request != null) {
      viewModel.applySavedExpense(request);
    }
  }

  Future<void> _confirmDelete(BuildContext context, SplitExpense expense) async {
    final viewModel = context.read<GroupDetailViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: '刪除帳目',
      message: '確定要刪除「${expense.name}」嗎？\n這個操作無法復原。',
      confirmLabel: '確認刪除',
    );
    if (!confirmed) {
      return;
    }
    final result = await viewModel.deleteExpense(expense);
    messenger.showMessage(switch (result) {
      Success() => '已刪除 ${expense.name}',
      Failure(:final message) => message,
    });
  }

  Future<void> _openSettlement(BuildContext context) {
    final viewModel = context.read<GroupDetailViewModel>();
    return showAppBottomSheet<void>(
      context,
      builder: (_) => ChangeNotifierProvider(
        create: (_) => SettlementViewModel(
          groupId: viewModel.group.groupId,
          splitRepository: context.read<SplitRepository>(),
        )..init(),
        child: SettlementSheet(groupName: viewModel.group.groupName),
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final viewModel = context.read<GroupDetailViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: '退出群組',
      message: '確定要退出此群組嗎？此操作無法復原。',
      confirmLabel: '退出',
      destructive: true,
    );
    if (!confirmed) {
      return;
    }
    switch (await viewModel.leaveGroup()) {
      case Success():
        navigator.pop();
        messenger.showMessage('已退出群組', duration: const Duration(seconds: 2));
      case Failure(:final message):
        messenger.showMessage(
          '退出群組失敗：$message',
          duration: const Duration(seconds: 3),
        );
    }
  }
}
