import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/split.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/sheets.dart';
import '../view_models/split_view_model.dart';
import '../widgets/group_editor_sheet.dart';
import '../widgets/split_widgets.dart';
import 'group_detail_screen.dart';

class SplitScreen extends StatelessWidget {
  const SplitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SplitViewModel>();
    final errorMessage = viewModel.errorMessage;

    return PageScaffold(
      title: '分帳',
      subtitle: '團體帳單、待付待收與共享紀錄。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          SplitSummaryCard(
            groupCount: viewModel.groupCount,
            payableTotal: viewModel.payableTotal,
            receivableTotal: viewModel.receivableTotal,
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: '我的群組'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _openGroupEditor(context, GroupEditorMode.create),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('建立群組'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _openGroupEditor(context, GroupEditorMode.join),
                  icon: const Icon(Icons.group_add),
                  label: const Text('加入群組'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (viewModel.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (errorMessage != null)
            ErrorStateCard(message: errorMessage, onRetry: viewModel.load)
          else if (viewModel.groups.isEmpty)
            const EmptyStateCard(
              icon: Icons.group_add,
              message: '還沒有群組，先建立一個吧。',
            )
          else
            for (final group in viewModel.groups)
              GroupCard(
                group: group,
                onTap: () => _openGroupDetail(context, group),
              ),
        ],
      ),
    );
  }

  Future<void> _openGroupEditor(
    BuildContext context,
    GroupEditorMode mode,
  ) {
    final viewModel = context.read<SplitViewModel>();
    return showAppBottomSheet<void>(
      context,
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: GroupEditorSheet(initialMode: mode),
      ),
    );
  }

  Future<void> _openGroupDetail(
    BuildContext context,
    GroupSummary group,
  ) async {
    final viewModel = context.read<SplitViewModel>();
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            GroupDetailScreen.route(group: group, userId: viewModel.userId),
      ),
    );
    await viewModel.load(silent: true);
  }
}
