part of '../main.dart';

class LedgerPage extends StatefulWidget {
  const LedgerPage({super.key});

  @override
  State<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends State<LedgerPage> {
  final List<LedgerItem> _items = ledgerItems;

  double get _incomeTotal => _items
      .where((item) => item.isIncome)
      .fold<double>(0, (sum, item) => sum + _parseAmount(item.amount));

  double get _expenseTotal => _items
      .where((item) => !item.isIncome)
      .fold<double>(0, (sum, item) => sum + _parseAmount(item.amount));

  double get _balance => _incomeTotal - _expenseTotal;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _PageScaffold(
          title: '記帳',
          subtitle: '收入與支出快速整理。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _BalanceCard(
                balance: _balance,
                income: _incomeTotal,
                expense: _expenseTotal,
              ),
              const SizedBox(height: 20),
              _SectionHeader(title: '最新紀錄'),
              const SizedBox(height: 12),
              if (_items.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: const [
                        Icon(Icons.receipt_long, color: AppColors.inkLight),
                        SizedBox(width: 12),
                        Expanded(child: Text('目前沒有記帳紀錄。')),
                      ],
                    ),
                  ),
                )
              else
                ..._items.map(
                  (item) => LedgerTile(
                    item: item,
                    onTap: () => _openDetailSheet(context, item),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: SafeArea(
            child: FloatingActionButton(
              onPressed: () => _openEntrySheet(context, isIncome: false),
              backgroundColor: AppColors.pinkPrimary,
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    );
  }

  void _openDetailSheet(BuildContext context, LedgerItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: Theme.of(sheetContext).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                item.subtitle,
                style: const TextStyle(color: AppColors.inkLight),
              ),
              const SizedBox(height: 18),
              _DetailRow(label: '類型', value: item.isIncome ? '收入' : '支出'),
              _DetailRow(label: '金額', value: item.amount),
              _DetailRow(label: '圖示', value: _ledgerCategoryName(item.icon)),
              _DetailRow(label: '時間', value: item.recordedAtLabel),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _openEntrySheet(
                          context,
                          isIncome: item.isIncome,
                          initialItem: item,
                        );
                      },
                      child: const Text('複製新增'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        setState(() => _items.remove(item));
                        _showSnackBar(context, '已刪除 ${item.title}');
                      },
                      child: const Text('刪除'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openEntrySheet(
    BuildContext context, {
    required bool isIncome,
    LedgerItem? initialItem,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _LedgerEntrySheet(
        initialItem: initialItem,
        isIncome: isIncome,
        onSave: (item) {
          setState(() {
            _items.insert(0, item);
          });
          _showSnackBar(
            context,
            '已新增${item.isIncome ? '收入' : '支出'}：${item.title}',
          );
        },
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.inkLight),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerEntrySheet extends StatefulWidget {
  const _LedgerEntrySheet({
    required this.isIncome,
    required this.onSave,
    this.initialItem,
  });

  final bool isIncome;
  final LedgerItem? initialItem;
  final ValueChanged<LedgerItem> onSave;

  @override
  State<_LedgerEntrySheet> createState() => _LedgerEntrySheetState();
}

class _LedgerEntrySheetState extends State<_LedgerEntrySheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late bool _selectedIncome;
  late String _selectedCategory;
  String? _linkedGoalTitle;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialItem?.title ?? '',
    );
    _amountController = TextEditingController(
      text: widget.initialItem?.amount.replaceAll(RegExp(r'[^0-9.]'), '') ?? '',
    );
    _noteController = TextEditingController(
      text: _extractNote(widget.initialItem?.subtitle ?? ''),
    );
    _selectedIncome = widget.initialItem?.isIncome ?? widget.isIncome;
    _selectedCategory = widget.initialItem != null
        ? _ledgerCategoryName(widget.initialItem!.icon)
        : (_selectedIncome
              ? _incomeCategories.first
              : _expenseCategories.first);
    _linkedGoalTitle = null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _selectedIncome ? _incomeCategories : _expenseCategories;
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = categories.first;
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initialItem == null ? '新增紀錄' : '複製新增',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '把日常收支直接記下來，示範資料會即時更新。',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.inkLight),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                children: [
                  ChoiceChip(
                    label: const Text('收入'),
                    selected: _selectedIncome,
                    onSelected: (_) {
                      setState(() {
                        _selectedIncome = true;
                        if (!(_incomeCategories.contains(_selectedCategory))) {
                          _selectedCategory = _incomeCategories.first;
                        }
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('支出'),
                    selected: !_selectedIncome,
                    onSelected: (_) {
                      setState(() {
                        _selectedIncome = false;
                        if (!(_expenseCategories.contains(_selectedCategory))) {
                          _selectedCategory = _expenseCategories.first;
                        }
                      });
                    },
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
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return '請輸入標題';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(_selectedCategory),
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: '分類'),
                items: categories
                    .map(
                      (value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _selectedCategory = value);
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
                validator: (value) {
                  final amount = double.tryParse(
                    (value ?? '').trim().replaceAll(',', ''),
                  );
                  if (amount == null) {
                    return '請輸入數字';
                  }
                  if (amount <= 0) {
                    return '金額必須大於 0';
                  }
                  return null;
                },
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
              DropdownButtonFormField<String?>(
                key: ValueKey(_linkedGoalTitle),
                initialValue: _linkedGoalTitle,
                decoration: const InputDecoration(labelText: '同步到目標'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('不同步'),
                  ),
                  ...goalItems.map(
                    (goal) => DropdownMenuItem<String?>(
                      value: goal.title,
                      child: Text(goal.title),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _linkedGoalTitle = value);
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      child: const Text('儲存'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final title = _titleController.text.trim();
    final amount = double.parse(
      _amountController.text.trim().replaceAll(',', ''),
    );
    final note = _noteController.text.trim();

    final resolvedAmount =
        '${_selectedIncome ? '+' : '-'}\$${_formatAmount(amount.abs())}';

    widget.onSave(
      LedgerItem(
        title: title,
        subtitle: note.isEmpty
            ? _selectedCategory
            : '$_selectedCategory · $note',
        amount: resolvedAmount,
        isIncome: _selectedIncome,
        icon: _iconForCategory(_selectedCategory, _selectedIncome),
        recordedAt: DateTime.now(),
      ),
    );

    if (_linkedGoalTitle != null) {
      _applyGoalImpact(_linkedGoalTitle!, amount, _selectedIncome);
    }

    Navigator.pop(context);
  }

  void _applyGoalImpact(String goalTitle, double amount, bool isIncome) {
    final index = goalItems.indexWhere((goal) => goal.title == goalTitle);
    if (index < 0) {
      return;
    }

    final delta = isIncome ? amount : -amount;
    final updatedSavedAmount = goalItems[index].savedAmount + delta;
    goalItems[index] = goalItems[index].copyWith(
      savedAmount: updatedSavedAmount < 0 ? 0 : updatedSavedAmount,
    );
  }
}

String _formatAmount(double value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final integer = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  if (parts[1] == '00') {
    return integer;
  }
  return '$integer.${parts[1]}';
}

double _parseAmount(String value) {
  return double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
}

String _extractNote(String subtitle) {
  final parts = subtitle.split(' · ');
  return parts.length > 1 ? parts.last : '';
}

IconData _iconForCategory(String category, bool isIncome) {
  if (isIncome) {
    return switch (category) {
      '薪資' => Icons.payments,
      '獎金' => Icons.workspace_premium,
      '退款' => Icons.keyboard_return,
      _ => Icons.savings,
    };
  }

  return switch (category) {
    '餐飲' => Icons.local_cafe,
    '購物' => Icons.shopping_bag,
    '交通' => Icons.directions_bus,
    '帳單' => Icons.receipt_long,
    _ => Icons.payments,
  };
}

String _ledgerCategoryName(IconData icon) {
  return switch (icon) {
    Icons.payments => '薪資',
    Icons.workspace_premium => '獎金',
    Icons.keyboard_return => '退款',
    Icons.local_cafe => '餐飲',
    Icons.shopping_bag => '購物',
    Icons.directions_bus => '交通',
    Icons.receipt_long => '帳單',
    _ => '其他',
  };
}

const List<String> _incomeCategories = ['薪資', '獎金', '退款', '其他'];
const List<String> _expenseCategories = ['餐飲', '購物', '交通', '帳單', '其他'];
