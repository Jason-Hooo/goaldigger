import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/result/result.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/split.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/sheets.dart';
import '../view_models/group_expense_editor_view_model.dart';

/// Create / edit form for a group expense, backed by
/// [GroupExpenseEditorViewModel]. Pops with the saved [SplitExpenseRequest].
class GroupExpenseEditorSheet extends StatefulWidget {
  const GroupExpenseEditorSheet({super.key});

  @override
  State<GroupExpenseEditorSheet> createState() =>
      _GroupExpenseEditorSheetState();
}

class _GroupExpenseEditorSheetState extends State<GroupExpenseEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  final Map<int, TextEditingController> _shareControllers = {};

  @override
  void initState() {
    super.initState();
    final initial = context.read<GroupExpenseEditorViewModel>().initialExpense;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _amountController = TextEditingController(
      text: initial?.amount.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    for (final controller in _shareControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _shareController(
    GroupExpenseEditorViewModel viewModel,
    GroupMember member,
  ) {
    return _shareControllers.putIfAbsent(member.userId, () {
      final initial = viewModel.initialShareFor(member.userId);
      return TextEditingController(text: initial?.toStringAsFixed(0) ?? '');
    });
  }

  double get _sharesTotal => _shareControllers.values.fold<double>(
    0,
    (sum, controller) => sum + (Formatters.parseAmount(controller.text) ?? 0),
  );

  void _onEdited(GroupExpenseEditorViewModel viewModel) {
    viewModel.clearValidationError();
    setState(() {});
  }

  void _splitEqually(GroupExpenseEditorViewModel viewModel) {
    final share = viewModel.equalShare(
      Formatters.parseAmount(_amountController.text),
    );
    if (share == null) {
      return;
    }
    for (final member in viewModel.members) {
      _shareController(viewModel, member).text = share.toStringAsFixed(0);
    }
    setState(() {});
  }

  Future<void> _save(GroupExpenseEditorViewModel viewModel) async {
    viewModel.clearValidationError();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final result = await viewModel.submit(
      name: _nameController.text.trim(),
      amount: Formatters.parseAmount(_amountController.text)!,
      shares: {
        for (final member in viewModel.members)
          member.userId:
              Formatters.parseAmount(
                _shareController(viewModel, member).text,
              ) ??
              0,
      },
    );
    if (!mounted) {
      return;
    }
    if (result case Success(value: final request)) {
      Navigator.pop(context, request);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GroupExpenseEditorViewModel>();
    final validationError = viewModel.validationError;
    final membersError = viewModel.membersError;

    return SheetBody(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SheetHeader(
              title: viewModel.isEditing ? '編輯群組帳目' : '新增群組帳目',
              subtitle: '為 ${viewModel.group.groupName} 新增一筆分帳紀錄',
            ),
            const SizedBox(height: 16),
            if (validationError != null) ...[
              InlineBanner(
                message: validationError,
                color: Colors.red,
                background: Colors.red.withValues(alpha: 0.1),
                textColor: Colors.red,
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '帳目名稱',
                hintText: '例如：晚餐',
              ),
              maxLength: 20,
              onChanged: (_) => _onEdited(viewModel),
              validator: Validators.required('請輸入帳目名稱'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: '總金額',
                prefixText: '\$',
                hintText: '例如 500',
              ),
              onChanged: (_) => _onEdited(viewModel),
              validator: Validators.positiveAmount,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              key: ValueKey('split-type-${viewModel.expenseTypes.length}'),
              initialValue: viewModel.selectedTypeId,
              decoration: const InputDecoration(
                labelText: '支出類別',
                hintText: '選擇類別',
              ),
              items: [
                for (final type in viewModel.expenseTypes)
                  DropdownMenuItem(value: type.id, child: Text(type.name)),
              ],
              onChanged: viewModel.selectType,
            ),
            const SizedBox(height: 16),
            Text('分攤金額', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (viewModel.isLoadingMembers)
              const Center(child: CircularProgressIndicator())
            else if (membersError != null)
              Card(
                color: AppColors.pinkSoft,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(membersError),
                ),
              )
            else
              for (final member in viewModel.members)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(child: Text(member.userName)),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: _shareController(viewModel, member),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            prefixText: '\$',
                            hintText: '0',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (_) => _onEdited(viewModel),
                          validator: Validators.nonNegativeAmount,
                        ),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '總計: \$${_sharesTotal.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ActionChip(
                  label: const Text('平均分攤'),
                  onPressed: () => _splitEqually(viewModel),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SheetActions(
              isBusy: viewModel.isSaving,
              onConfirm: () => _save(viewModel),
            ),
          ],
        ),
      ),
    );
  }
}
