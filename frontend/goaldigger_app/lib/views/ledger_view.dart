part of '../main.dart';

class LedgerPage extends StatefulWidget {
  const LedgerPage({super.key, required this.user});

  final AuthUser user;

  @override
  State<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends State<LedgerPage> {
  final ApiConnect _api = ApiConnect();
  List<LedgerItem> _items = [];
  List<ExpenseType> _expenseTypes = [];
  List<GoalItem> _goals = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _hasLoadedOnce = false;
  String? _errorMessage;

  double get _incomeTotal => _items
      .where((item) => item.isIncome)
      .fold<double>(0, (sum, item) => sum + _parseAmount(item.amount));

  double get _expenseTotal => _items
      .where((item) => !item.isIncome)
      .fold<double>(0, (sum, item) => sum + _parseAmount(item.amount));

  double get _balance => _incomeTotal - _expenseTotal;

  @override
  void initState() {
    super.initState();
    _loadLedger();
    AppRefreshBus.tick.addListener(_onAppRefresh);
  }

  void _onAppRefresh() {
    if (mounted) {
      unawaited(_loadLedger(silent: true));
    }
  }

  Future<void> _loadLedger({bool silent = false}) async {
    if (!silent || !_hasLoadedOnce) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else if (mounted) {
      setState(() => _isRefreshing = true);
    }

    try {
      final results = await Future.wait([
        _api.fetchExpenseTypes(widget.user.userId),
        _api.fetchGoals(widget.user.userId),
        _api.fetchLedgerHistory(widget.user.userId, limit: 80),
      ]);
      final types = results[0] as List<ExpenseType>;
      final goals = results[1] as List<GoalItem>;
      final records = results[2] as List<LedgerRecord>;
      if (!mounted) {
        return;
      }

      setState(() {
        _expenseTypes = types;
        _goals = goals;
        _items = records.map((record) => _mapLedgerItem(record)).toList();
        _hasLoadedOnce = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = _readableError(error));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  LedgerItem _mapLedgerItem(LedgerRecord record) {
    final type = _expenseTypes
        .cast<ExpenseType?>()
        .firstWhere((item) => item?.id == record.typeId, orElse: () => null);
    final typeName = record.typeName ?? type?.name ?? '未分類';
    final isIncome = record.isExpense == null
        ? !(type?.isExpense ?? true)
        : !(record.isExpense ?? true);

    final description = (record.description ?? '').trim();
    final parts = description.split(' · ');
    final title = parts.firstWhere((part) => part.isNotEmpty, orElse: () => typeName);
    final note = parts.length > 1 ? parts.sublist(1).join(' · ') : '';
    final subtitle = note.isEmpty ? typeName : '$typeName · $note';

    return LedgerItem(
      recordId: record.recordId,
      typeId: record.typeId,
      goalId: record.goalId,
      categoryName: typeName,
      title: title,
      subtitle: subtitle,
      amount: '${isIncome ? '+' : '-'}\$${_formatAmount(record.amount)}',
      isIncome: isIncome,
      icon: _iconForCategory(typeName, isIncome),
      recordedAt: record.createdAt,
    );
  }

  LedgerRecord _buildOptimisticLedgerRecord(
    _LedgerDraft draft, {
    int? recordId,
    DateTime? createdAt,
  }) {
    return LedgerRecord(
      recordId: recordId ?? -DateTime.now().microsecondsSinceEpoch,
      typeId: draft.typeId,
      amount: draft.amount,
      createdAt: createdAt ?? DateTime.now(),
      description: draft.description,
      typeName: null,
      isExpense: !draft.isIncome,
      goalId: draft.goalId,
    );
  }

  void _upsertLedgerItem(LedgerItem item, {bool isNew = false}) {
    setState(() {
      final nextItems = List<LedgerItem>.from(_items);
      final existingIndex = nextItems.indexWhere((entry) => entry.recordId == item.recordId);
      if (existingIndex >= 0) {
        nextItems[existingIndex] = item;
      } else if (isNew) {
        nextItems.insert(0, item);
      } else {
        nextItems.insert(0, item);
      }
      _items = nextItems;
    });
  }

  void _removeLedgerItem(int recordId) {
    setState(() {
      _items = _items.where((item) => item.recordId != recordId).toList();
    });
  }

  String _readableError(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return '資料讀取失敗，請稍後再試。';
  }

  @override
Widget build(BuildContext context) {
  return SizedBox.expand( // 👈 關鍵：強制讓整個 Stack 佔滿全螢幕高度
    child: Stack(
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
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_errorMessage != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.pinkPrimary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_errorMessage!)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _loadLedger,
                            child: const Text('重試'),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_items.isEmpty)
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
                Column(
                  children: [
                    if (_isRefreshing)
                      const LinearProgressIndicator(minHeight: 2),
                    ..._items.map(
                      (item) => LedgerTile(
                        item: item,
                        onTap: () => _openDetailSheet(context, item),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: SafeArea(
            child: FloatingActionButton(
              heroTag: 'fab-ledger',
              onPressed: () => _openEntrySheet(context, isIncome: false),
              backgroundColor: AppColors.pinkPrimary,
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    ),
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
              _DetailRow(
                label: '分類',
                value: item.categoryName ?? _ledgerCategoryName(item.icon),
              ),
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
                          isEditing: true,
                        );
                      },
                      child: const Text('編輯'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _openEntrySheet(
                          context,
                          isIncome: item.isIncome,
                          initialItem: item,
                          isEditing: false,
                        );
                      },
                      child: const Text('複製新增'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await _deleteLedger(item);
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
    bool isEditing = false,
  }) async {
    if (_expenseTypes.isEmpty) {
      _showSnackBar(context, '尚未取得分類資料，請稍後再試。');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _LedgerEntrySheet(
        expenseTypes: _expenseTypes,
        goals: _goals,
        initialItem: initialItem,
        isIncome: isIncome,
        isEditing: isEditing,
        onSave: _saveLedger,
      ),
    );
  }

  Future<void> _saveLedger(_LedgerDraft draft) async {
    final previousItems = List<LedgerItem>.from(_items);
    DateTime? createdAt;
    if (draft.recordId != null) {
      final existingIndex = _items.indexWhere((item) => item.recordId == draft.recordId);
      if (existingIndex >= 0) {
        createdAt = _items[existingIndex].recordedAt;
      }
    }
    final optimisticRecord = _buildOptimisticLedgerRecord(
      draft,
      recordId: draft.recordId,
      createdAt: createdAt,
    );
    final optimisticItem = _mapLedgerItem(optimisticRecord);

    _upsertLedgerItem(optimisticItem, isNew: draft.recordId == null);

    try {
      if (draft.recordId == null) {
        await _api.createLedger(
          userId: widget.user.userId,
          typeId: draft.typeId,
          amount: draft.amount,
          description: draft.description,
          goalId: draft.goalId,
        );
      } else {
        await _api.updateLedger(
          recordId: draft.recordId!,
          userId: widget.user.userId,
          typeId: draft.typeId,
          amount: draft.amount,
          description: draft.description,
          goalId: draft.goalId,
        );
      }
      AppRefreshBus.notifyChanged();
      unawaited(_loadLedger(silent: true));
      if (!mounted) {
        return;
      }
      _showSnackBar(
        context,
        draft.recordId == null
            ? '已新增${draft.isIncome ? '收入' : '支出'}：${draft.title}'
            : '已更新${draft.isIncome ? '收入' : '支出'}：${draft.title}',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _items = previousItems;
      });
      _showSnackBar(context, _readableError(error));
    }
  }

  Future<void> _deleteLedger(LedgerItem item) async {
    if (item.recordId == null) {
      _showSnackBar(context, '缺少紀錄編號，無法刪除。');
      return;
    }

    // Check if ledger entry is synced with an achieved goal
    if (item.goalId != null) {
      final goal = _goals.firstWhere(
        (g) => g.goalId == item.goalId,
        orElse: () => GoalItem(
          title: '',
          description: '',
          targetAmount: 0,
          deadline: DateTime.now(),
        ),
      );
      if (goal.isAchieved) {
        _showSnackBar(context, '此帳目已同步至已達成的目標，無法刪除。');
        return;
      }
    }

    final previousItems = List<LedgerItem>.from(_items);
    _removeLedgerItem(item.recordId!);

    try {
      await _api.deleteLedger(item.recordId!, goalId: item.goalId);
      AppRefreshBus.notifyChanged();
      unawaited(_loadLedger(silent: true));
      _showSnackBar(context, '已刪除 ${item.title}');
    } catch (error) {
      setState(() {
        _items = previousItems;
      });
      _showSnackBar(context, _readableError(error));
    }
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
    required this.expenseTypes,
    required this.goals,
    required this.isEditing,
    this.initialItem,
  });

  final bool isIncome;
  final LedgerItem? initialItem;
  final bool isEditing;
  final ValueChanged<_LedgerDraft> onSave;
  final List<ExpenseType> expenseTypes;
  final List<GoalItem> goals;

  @override
  State<_LedgerEntrySheet> createState() => _LedgerEntrySheetState();
}

class _LedgerEntrySheetState extends State<_LedgerEntrySheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late bool _selectedIncome;
  int? _selectedTypeId;
  int? _linkedGoalId;
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
    _selectedTypeId = _resolveInitialTypeId(widget.initialItem?.typeId);
    _linkedGoalId = widget.initialItem?.goalId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<ExpenseType> get _incomeTypes =>
      widget.expenseTypes.where((type) => !type.isExpense).toList();

  List<ExpenseType> get _expenseTypes =>
      widget.expenseTypes.where((type) => type.isExpense).toList();

  int? _resolveInitialTypeId(int? initialId) {
    final types = _selectedIncome ? _incomeTypes : _expenseTypes;
    if (initialId != null && types.any((type) => type.id == initialId)) {
      return initialId;
    }
    return types.isNotEmpty ? types.first.id : null;
  }

  ExpenseType? _findTypeById(int? typeId) {
    if (typeId == null) {
      return null;
    }
    return widget.expenseTypes
        .cast<ExpenseType?>()
        .firstWhere((item) => item?.id == typeId, orElse: () => null);
  }

  @override
  Widget build(BuildContext context) {
    final categories = _selectedIncome ? _incomeTypes : _expenseTypes;
    if (categories.isNotEmpty &&
        categories.every((type) => type.id != _selectedTypeId)) {
      _selectedTypeId = categories.first.id;
    }

    // Check if linked goal still exists, if not reset to null
    if (_linkedGoalId != null &&
        !widget.goals.any((goal) => goal.goalId == _linkedGoalId)) {
      _linkedGoalId = null;
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
                widget.initialItem == null
                    ? '新增紀錄'
                    : (widget.isEditing ? '編輯紀錄' : '複製新增'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '把日常收支直接記下來，系統會即時同步。',
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
                        _selectedTypeId = _resolveInitialTypeId(_selectedTypeId);
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('支出'),
                    selected: !_selectedIncome,
                    onSelected: (_) {
                      setState(() {
                        _selectedIncome = false;
                        _selectedTypeId = _resolveInitialTypeId(_selectedTypeId);
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
              DropdownButtonFormField<int>(
                key: Key('type-${_selectedTypeId ?? 'none'}'),
                initialValue: _selectedTypeId,
                decoration: const InputDecoration(labelText: '分類'),
                items: categories
                    .map(
                      (type) => DropdownMenuItem<int>(
                        value: type.id,
                        child: Text(type.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _selectedTypeId = value);
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
              DropdownButtonFormField<int?>(
                key: Key('goal-${_linkedGoalId ?? 'none'}'),
                value: _linkedGoalId,
                decoration: const InputDecoration(labelText: '同步到目標'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('不同步'),
                  ),
                  ...widget.goals.map(
                    (goal) => DropdownMenuItem<int?>(
                      value: goal.goalId,
                      child: Text(goal.title),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _linkedGoalId = value);
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
                      child: Text(widget.initialItem == null ? '建立' : '儲存'),
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

    if (_selectedTypeId == null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('請先選擇分類。')));
      return;
    }

    final title = _titleController.text.trim();
    final amount = double.parse(
      _amountController.text.trim().replaceAll(',', ''),
    );
    final note = _noteController.text.trim();

    final type = _findTypeById(_selectedTypeId);
    final typeName = type?.name ?? '未分類';
    final description = note.isEmpty ? title : '$title · $note';

    widget.onSave(
      _LedgerDraft(
        recordId: widget.isEditing ? widget.initialItem?.recordId : null,
        title: title,
        categoryName: typeName,
        amount: amount,
        isIncome: _selectedIncome,
        description: description,
        typeId: _selectedTypeId!,
        goalId: _linkedGoalId,
      ),
    );

    Navigator.pop(context);
  }
}

class _LedgerDraft {
  const _LedgerDraft({
    this.recordId,
    required this.title,
    required this.categoryName,
    required this.amount,
    required this.isIncome,
    required this.description,
    required this.typeId,
    this.goalId,
  });

  final int? recordId;
  final String title;
  final String categoryName;
  final double amount;
  final bool isIncome;
  final String description;
  final int typeId;
  final int? goalId;
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
