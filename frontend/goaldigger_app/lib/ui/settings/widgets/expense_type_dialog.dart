import 'package:flutter/material.dart';

import '../../../core/utils/validators.dart';
import '../../../data/models/expense_type.dart';

/// Create / edit dialog for a custom category. Pops with an
/// [ExpenseTypeDraft] on confirm.
class ExpenseTypeDialog extends StatefulWidget {
  const ExpenseTypeDialog({super.key, this.initialType});

  final ExpenseType? initialType;

  @override
  State<ExpenseTypeDialog> createState() => _ExpenseTypeDialogState();
}

class _ExpenseTypeDialogState extends State<ExpenseTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController = TextEditingController(
    text: widget.initialType?.name ?? '',
  );
  late bool _isExpense = widget.initialType?.isExpense ?? true;

  bool get _isNew => widget.initialType == null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop(
      ExpenseTypeDraft(
        name: _nameController.text.trim(),
        isExpense: _isExpense,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isNew ? '新增自訂類別' : '編輯自訂類別'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('只會顯示在你的帳號中。'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '類別名稱',
                hintText: '例如：外送、投資、獎金',
              ),
              maxLength: 20,
              validator: Validators.required('請輸入類別名稱'),
            ),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('支出')),
                ButtonSegment(value: false, label: Text('收入')),
              ],
              selected: {_isExpense},
              onSelectionChanged: (selection) =>
                  setState(() => _isExpense = selection.first),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(_isNew ? '建立' : '儲存'),
        ),
      ],
    );
  }
}
