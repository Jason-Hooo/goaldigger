part of '../main.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.onLogout, required this.user});

  final VoidCallback onLogout;
  final AuthUser user;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  late final List<Widget> _pages = [
    LedgerPage(user: widget.user),
    GoalsPage(user: widget.user),
    StatsPage(user: widget.user),
    SplitPage(user: widget.user),
    SettingsPage(onLogout: widget.onLogout, user: widget.user),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const PinkBackground(),
          SafeArea(
            child: IndexedStack(
              index: _index,
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 14,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (value) => setState(() => _index = value),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.pinkPrimary,
          unselectedItemColor: AppColors.inkLight,
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: '記帳',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.flag_rounded),
              label: '目標',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              label: '報表',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_rounded),
              label: '分帳',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: '設定',
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.onLogout, required this.user});

  final VoidCallback onLogout;
  final AuthUser user;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ApiConnect _api = ApiConnect();
  List<ExpenseType> _expenseTypes = [];
  bool _isLoadingTypes = true;
  String? _typesError;

  @override
  void initState() {
    super.initState();
    _loadExpenseTypes();
  }

  List<ExpenseType> get _customExpenseTypes => _expenseTypes
      .where((type) => type.ownerUserId == widget.user.userId)
      .toList();

  Future<void> _loadExpenseTypes() async {
    setState(() {
      _isLoadingTypes = true;
      _typesError = null;
    });

    try {
      final types = await _api.fetchExpenseTypes(widget.user.userId);
      if (!mounted) {
        return;
      }
      setState(() => _expenseTypes = types);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _typesError = _readableError(error));
    } finally {
      if (mounted) {
        setState(() => _isLoadingTypes = false);
      }
    }
  }

  String _readableError(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return '讀取失敗，請稍後再試。';
  }

  Future<void> _openExpenseTypeDialog({ExpenseType? initialType}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => _ExpenseTypeDialog(initialType: initialType),
    );

    if (result == null) {
      return;
    }

    // Optimistic create/update
    if (initialType == null) {
      // create temp
      final temp = ExpenseType(
        id: -DateTime.now().microsecondsSinceEpoch,
        name: result['type_name'] as String,
        isExpense: result['is_expense'] as bool,
        ownerUserId: widget.user.userId,
      );
      setState(() => _expenseTypes.insert(0, temp));
      AppRefreshBus.notifyChanged();

      try {
        final created = await _api.createExpenseType(
          userId: widget.user.userId,
          typeName: result['type_name'] as String,
          isExpense: result['is_expense'] as bool,
        );
        if (!mounted) return;
        setState(() {
          final idx = _expenseTypes.indexWhere((t) => t.id == temp.id);
          if (idx >= 0) _expenseTypes[idx] = created;
        });
        AppRefreshBus.notifyChanged();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已新增自訂類別')));
      } catch (error) {
        if (!mounted) return;
        setState(() => _expenseTypes.removeWhere((t) => t.id == temp.id));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_readableError(error))));
      }
    } else {
      final prev = List<ExpenseType>.from(_expenseTypes);
      setState(() {
        final idx = _expenseTypes.indexWhere((t) => t.id == initialType.id);
        if (idx >= 0) {
          _expenseTypes[idx] = ExpenseType(
            id: initialType.id,
            name: result['type_name'] as String,
            isExpense: result['is_expense'] as bool,
            ownerUserId: initialType.ownerUserId,
          );
        }
      });
      AppRefreshBus.notifyChanged();

      try {
        final updated = await _api.updateExpenseType(
          typeId: initialType.id,
          userId: widget.user.userId,
          typeName: result['type_name'] as String,
          isExpense: result['is_expense'] as bool,
        );
        if (!mounted) return;
        setState(() {
          final idx = _expenseTypes.indexWhere((t) => t.id == updated.id);
          if (idx >= 0) _expenseTypes[idx] = updated;
        });
        AppRefreshBus.notifyChanged();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已更新類別')));
      } catch (error) {
        if (!mounted) return;
        setState(() => _expenseTypes = prev);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_readableError(error))));
      }
    }
  }

  Future<void> _deleteExpenseType(ExpenseType type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('刪除自訂類別'),
        content: Text('確定要刪除「${type.name}」嗎？\n若已有記帳紀錄，後端會阻止刪除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.pinkPrimary),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    // Optimistic delete
    final previous = List<ExpenseType>.from(_expenseTypes);
    setState(() => _expenseTypes.removeWhere((t) => t.id == type.id));
    AppRefreshBus.notifyChanged();

    try {
      await _api.deleteExpenseType(
        typeId: type.id,
        userId: widget.user.userId,
      );
      AppRefreshBus.notifyChanged();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已刪除自訂類別')));
    } catch (error) {
      if (!mounted) return;
      setState(() => _expenseTypes = previous);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_readableError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: '設定',
      subtitle: '管理帳號與偏好設定。',
      child: Column(
        children: [
          const SizedBox(height: 12),
          Card(
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
                          widget.user.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.user.email,
                    style: const TextStyle(color: AppColors.inkLight),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: widget.onLogout,
                    icon: const Icon(Icons.logout),
                    label: const Text('登出'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
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
                        onPressed: () => _openExpenseTypeDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('新增類別'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 12),
                  if (_isLoadingTypes)
                    const Center(child: CircularProgressIndicator())
                  else if (_typesError != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_typesError!),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loadExpenseTypes,
                          child: const Text('重試'),
                        ),
                      ],
                    )
                  else
                    _buildExpenseTypeSection(
                      title: '我的自訂',
                      types: _customExpenseTypes,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseTypeSection({
    required String title,
    required List<ExpenseType> types,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (types.isEmpty)
          const Text(
            '目前尚未建立自訂類別。',
            style: TextStyle(color: AppColors.inkLight),
          )
        else
          ...types.map(
            (type) => Card(
              key: ValueKey('expense-type-${type.id}'),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.pinkSoft,
                  child: const Icon(
                    Icons.category_outlined,
                    color: AppColors.pinkPrimary,
                  ),
                ),
                title: Text(type.name),
                subtitle: Text(type.isExpense ? '支出' : '收入'),
                trailing: const Icon(Icons.more_vert),
                onTap: () async {
                  final result = await showModalBottomSheet<String>(
                    context: context,
                    builder: (sheetContext) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.edit_outlined),
                            title: const Text('編輯'),
                            onTap: () {
                              Navigator.pop(sheetContext, 'edit');
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.delete_outline, color: Colors.red),
                            title: const Text('刪除', style: TextStyle(color: Colors.red)),
                            onTap: () {
                              Navigator.pop(sheetContext, 'delete');
                            },
                          ),
                        ],
                      ),
                    ),
                  );

                  if (result == 'edit') {
                    _openExpenseTypeDialog(initialType: type);
                  } else if (result == 'delete') {
                    _deleteExpenseType(type);
                  }
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _ExpenseTypeDialog extends StatefulWidget {
  const _ExpenseTypeDialog({this.initialType});

  final ExpenseType? initialType;

  @override
  State<_ExpenseTypeDialog> createState() => _ExpenseTypeDialogState();
}

class _ExpenseTypeDialogState extends State<_ExpenseTypeDialog> {
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isExpense = true;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialType?.name ?? '';
    _isExpense = widget.initialType?.isExpense ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialType == null ? '新增自訂類別' : '編輯自訂類別'),
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
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return '請輸入類別名稱';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: true,
                  label: Text('支出'),
                ),
                ButtonSegment<bool>(
                  value: false,
                  label: Text('收入'),
                ),
              ],
              selected: {_isExpense},
              onSelectionChanged: (selection) {
                setState(() => _isExpense = selection.first);
              },
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
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) {
              return;
            }
            final name = _nameController.text.trim();
            Navigator.of(context).pop({
              'type_name': name,
              'is_expense': _isExpense,
            });
          },
          child: Text(widget.initialType == null ? '建立' : '儲存'),
        ),
      ],
    );
  }
}
