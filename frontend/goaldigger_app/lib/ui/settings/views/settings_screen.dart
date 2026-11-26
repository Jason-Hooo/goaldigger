import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/result/result.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/auth_user.dart';
import '../../../data/models/expense_type.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/sheets.dart';
import '../../session/session_view_model.dart';
import '../view_models/settings_view_model.dart';
import '../widgets/expense_type_dialog.dart';

enum _TypeAction { edit, delete }

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '設定',
      subtitle: '管理帳號與偏好設定。',
      child: Column(
        children: [
          const SizedBox(height: 12),
          _AccountCard(user: user),
          const SizedBox(height: 16),
          const _ExpenseTypesCard(),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('帳號', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.pinkSoft,
                  child: Icon(
                    Icons.person_rounded,
                    color: AppColors.pinkPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(user.email, style: const TextStyle(color: AppColors.inkLight)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: context.read<SessionViewModel>().signOut,
              icon: const Icon(Icons.logout),
              label: const Text('登出'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseTypesCard extends StatelessWidget {
  const _ExpenseTypesCard();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    final errorMessage = viewModel.errorMessage;
    final types = viewModel.customTypes;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '記帳類別',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openEditor(context),
                  icon: const Icon(Icons.add),
                  label: const Text('新增類別'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (viewModel.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(errorMessage),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: viewModel.load,
                    child: const Text('重試'),
                  ),
                ],
              )
            else ...[
              Text('我的自訂', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (types.isEmpty)
                const Text(
                  '目前尚未建立自訂類別。',
                  style: TextStyle(color: AppColors.inkLight),
                )
              else
                for (final type in types)
                  Card(
                    key: ValueKey('expense-type-${type.id}'),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.pinkSoft,
                        child: Icon(
                          Icons.category_outlined,
                          color: AppColors.pinkPrimary,
                        ),
                      ),
                      title: Text(type.name),
                      subtitle: Text(type.isExpense ? '支出' : '收入'),
                      trailing: const Icon(Icons.more_vert),
                      onTap: () => _openActions(context, type),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openActions(BuildContext context, ExpenseType type) async {
    final action = await showModalBottomSheet<_TypeAction>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('編輯'),
              onTap: () => Navigator.pop(sheetContext, _TypeAction.edit),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('刪除', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(sheetContext, _TypeAction.delete),
            ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) {
      return;
    }
    switch (action) {
      case _TypeAction.edit:
        await _openEditor(context, type);
      case _TypeAction.delete:
        await _confirmDelete(context, type);
    }
  }

  Future<void> _openEditor(BuildContext context, [ExpenseType? type]) async {
    final viewModel = context.read<SettingsViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final draft = await showDialog<ExpenseTypeDraft>(
      context: context,
      builder: (_) => ExpenseTypeDialog(initialType: type),
    );
    if (draft == null) {
      return;
    }
    final result = type == null
        ? await viewModel.create(draft)
        : await viewModel.update(type, draft);
    messenger.showMessage(switch (result) {
      Success() => type == null ? '已新增自訂類別' : '已更新類別',
      Failure(:final message) => message,
    });
  }

  Future<void> _confirmDelete(BuildContext context, ExpenseType type) async {
    final viewModel = context.read<SettingsViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: '刪除自訂類別',
      message: '確定要刪除「${type.name}」嗎？\n若已有記帳紀錄，後端會阻止刪除。',
      confirmLabel: '刪除',
    );
    if (!confirmed) {
      return;
    }
    final result = await viewModel.delete(type);
    messenger.showMessage(switch (result) {
      Success() => '已刪除自訂類別',
      Failure(:final message) => message,
    });
  }
}
