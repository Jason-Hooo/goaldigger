import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/goal.dart';
import '../../core/widgets/sheets.dart';

/// Create / edit form for a goal. Pops with the resulting [Goal].
class GoalEditorSheet extends StatefulWidget {
  const GoalEditorSheet({super.key, this.initialGoal});

  final Goal? initialGoal;

  @override
  State<GoalEditorSheet> createState() => _GoalEditorSheetState();
}

class _GoalEditorSheetState extends State<GoalEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _targetController;
  late final TextEditingController _savedController;
  late DateTime _deadline;

  @override
  void initState() {
    super.initState();
    final goal = widget.initialGoal;
    _titleController = TextEditingController(text: goal?.title ?? '');
    _descriptionController = TextEditingController(
      text: goal?.description ?? '',
    );
    _targetController = TextEditingController(
      text: goal?.targetAmount.toStringAsFixed(0) ?? '',
    );
    _savedController = TextEditingController(
      text: goal?.savedAmount.toStringAsFixed(0) ?? '0',
    );
    _deadline = goal?.deadline ?? DateTime.now().add(const Duration(days: 90));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    _savedController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: _deadline.isBefore(today) ? today : _deadline,
      firstDate: today,
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (selected != null) {
      setState(() => _deadline = selected);
    }
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final initial = widget.initialGoal;
    Navigator.pop(
      context,
      Goal(
        goalId: initial?.goalId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        targetAmount: Formatters.parseAmount(_targetController.text)!,
        deadline: _deadline,
        savedAmount: Formatters.parseAmount(_savedController.text) ?? 0,
        achievedAt: initial?.achievedAt,
        status: initial?.status,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SheetBody(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SheetHeader(
              title: widget.initialGoal == null ? '新增目標' : '編輯目標',
              subtitle: '把想買的東西、金額和期限先記起來。',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '目標名稱',
                hintText: '例如：相機基金',
              ),
              maxLength: 20,
              validator: Validators.required('請輸入目標名稱'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '描述',
                hintText: '例如：想買 Sony 相機和鏡頭',
              ),
              maxLines: 2,
              maxLength: 80,
              validator: Validators.required('請輸入目標描述'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _targetController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: '目標金額',
                hintText: '例如 1200',
                prefixText: '\$',
              ),
              validator: (value) =>
                  Validators.positiveAmount(value, message: '目標金額必須大於 0'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _savedController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: '目前已存',
                hintText: '例如 600',
                prefixText: '\$',
              ),
              validator: Validators.number,
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(labelText: '截止日期'),
              child: Row(
                children: [
                  Expanded(child: Text(Formatters.shortDate(_deadline))),
                  TextButton(
                    onPressed: _pickDeadline,
                    child: const Text('選日期'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SheetActions(onConfirm: _save),
          ],
        ),
      ),
    );
  }
}
