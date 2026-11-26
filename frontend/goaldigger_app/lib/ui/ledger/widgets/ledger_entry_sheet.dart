import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/expense_type.dart';
import '../../../data/models/goal.dart';
import '../../core/widgets/sheets.dart';
import '../view_models/ledger_entry.dart';

enum LedgerEntryMode { create, edit, duplicate }

/// Form for creating, editing or duplicating a ledger entry. Pops with a
/// [LedgerDraft] on save.
class LedgerEntrySheet extends StatefulWidget {
  const LedgerEntrySheet({
    super.key,
    required this.expenseTypes,
    required this.goals,
    required this.mode,
    this.initialEntry,
    this.defaultIsIncome = false,
  });

  final List<ExpenseType> expenseTypes;
  final List<Goal> goals;
  final LedgerEntryMode mode;
  final LedgerEntry? initialEntry;
  final bool defaultIsIncome;

  @override
  State<LedgerEntrySheet> createState() => _LedgerEntrySheetState();
}

class _LedgerEntrySheetState extends State<LedgerEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late bool _isIncome;
  int? _typeId;
  int? _goalId;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialEntry;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _amountController = TextEditingController(
      text: initial == null ? '' : Formatters.editable(initial.amount),
    );
    _noteController = TextEditingController(text: initial?.note ?? '');
    _isIncome = initial?.isIncome ?? widget.defaultIsIncome;
    _typeId = _resolveTypeId(initial?.typeId);
    _goalId = initial?.goalId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<ExpenseType> get _categories => widget.expenseTypes
      .where((type) => type.isExpense != _isIncome)
      .toList();

  int? _resolveTypeId(int? preferred) {
    final categories = _categories;
    if (preferred != null && categories.any((type) => type.id == preferred)) {
      return preferred;
    }
    return categories.isNotEmpty ? categories.first.id : null;
  }

  void _setIncome(bool isIncome) {
    setState(() {
      _isIncome = isIncome;
      _typeId = _resolveTypeId(_typeId);
    });
  }

  String get _title => switch (widget.mode) {
    LedgerEntryMode.create => '新增紀錄',
    LedgerEntryMode.edit => '編輯紀錄',
    LedgerEntryMode.duplicate => '複製新增',
  };

  @override
  Widget build(BuildContext context) {
    final categories = _categories;
    if (_goalId != null && !widget.goals.any((g) => g.goalId == _goalId)) {
      _goalId = null;
    }

    return SheetBody(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SheetHeader(title: _title, subtitle: '把日常收支直接記下來，系統會即時同步。'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              children: [
                ChoiceChip(
                  label: const Text('收入'),
                  selected: _isIncome,
                  onSelected: (_) => _setIncome(true),
                ),
                ChoiceChip(
                  label: const Text('支出'),
                  selected: !_isIncome,
                  onSelected: (_) => _setIncome(false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '標題',
                hintText: '例如：早午餐、薪資入帳',
              ),
              maxLength: 30,
              validator: Validators.required('請輸入標題'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              key: ValueKey('type-${_isIncome ? 'in' : 'out'}-$_typeId'),
              initialValue: _typeId,
              decoration: const InputDecoration(labelText: '分類'),
              items: [
                for (final type in categories)
                  DropdownMenuItem(value: type.id, child: Text(type.name)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _typeId = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: '金額',
                prefixText: '\$',
                hintText: '0.00',
              ),
              validator: Validators.positiveAmount,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: '備註',
                hintText: '例如：午餐、專案獎金',
              ),
              maxLength: 60,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              key: ValueKey('goal-$_goalId'),
              initialValue: _goalId,
              decoration: const InputDecoration(labelText: '同步到目標'),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('不同步')),
                for (final goal in widget.goals)
                  DropdownMenuItem<int?>(
                    value: goal.goalId,
                    child: Text(goal.title),
                  ),
              ],
              onChanged: (value) => setState(() => _goalId = value),
            ),
            const SizedBox(height: 20),
            SheetActions(
              confirmLabel: widget.mode == LedgerEntryMode.create ? '建立' : '儲存',
              onConfirm: _save,
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final typeId = _typeId;
    if (typeId == null) {
      ScaffoldMessenger.of(context).showMessage('請先選擇分類。');
      return;
    }

    Navigator.pop(
      context,
      LedgerDraft(
        recordId: widget.mode == LedgerEntryMode.edit
            ? widget.initialEntry?.recordId
            : null,
        title: _titleController.text.trim(),
        note: _noteController.text.trim(),
        amount: Formatters.parseAmount(_amountController.text)!,
        isIncome: _isIncome,
        typeId: typeId,
        goalId: _goalId,
      ),
    );
  }
}
