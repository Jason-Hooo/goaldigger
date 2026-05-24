part of '../main.dart';

class SplitPage extends StatefulWidget {
  const SplitPage({super.key});

  @override
  State<SplitPage> createState() => _SplitPageState();
}

class _SplitPageState extends State<SplitPage> {
  final List<SplitItem> _items = splitItems;

  int get _syncedCount => _items.where((item) => item.syncedToLedger).length;

  int get _confirmedCount =>
      _items.where((item) => item.confirmationSent).length;

  int get _memberCount => _items.expand((item) => item.members).toSet().length;

  @override
  Widget build(BuildContext context) {
    final totalPayable = _items
        .where((item) => item.amount.startsWith('待付'))
        .fold<double>(0, (sum, item) => sum + _parseAmount(item.amount));
    final totalReceivable = _items
        .where((item) => item.amount.startsWith('待收'))
        .fold<double>(0, (sum, item) => sum + _parseAmount(item.amount));

    return Stack(
      children: [
        _PageScaffold(
          title: '分帳',
          subtitle: '團體帳單、待付待收與共享紀錄。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _SplitSummaryCard(
                groupCount: _uniqueGroupTitles().length,
                payableTotal: totalPayable,
                receivableTotal: totalReceivable,
                syncedCount: _syncedCount,
                confirmedCount: _confirmedCount,
              ),
              const SizedBox(height: 20),
              _SectionHeader(title: '群組管理'),
              const SizedBox(height: 12),
              _SplitGroupActionsCard(
                groupCount: _uniqueGroupTitles().length,
                memberCount: _memberCount,
                onCreateGroup: () =>
                    _openEditorSheet(context, presetGroupMode: '建立群組'),
                onJoinGroup: () =>
                    _openEditorSheet(context, presetGroupMode: '加入群組'),
              ),
              const SizedBox(height: 16),
              _MiniRow(
                items: _uniqueGroupTitles()
                    .map((title) => _Pill(label: title))
                    .toList(),
              ),
              const SizedBox(height: 16),
              _SectionHeader(title: '分帳紀錄'),
              const SizedBox(height: 12),
              if (_items.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: const [
                        Icon(Icons.group_rounded, color: AppColors.inkLight),
                        SizedBox(width: 12),
                        Expanded(child: Text('還沒有分帳紀錄，先按右下角新增一筆。')),
                      ],
                    ),
                  ),
                )
              else
                ..._items.map(
                  (item) => SplitTile(
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
              onPressed: () => _openEditorSheet(context),
              backgroundColor: AppColors.pinkPrimary,
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    );
  }

  List<String> _uniqueGroupTitles() {
    final titles = <String>{};
    for (final item in _items) {
      titles.add(item.title);
    }
    return titles.toList();
  }

  void _openDetailSheet(BuildContext context, SplitItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return _SplitDetailSheet(
          item: item,
          onEdit: () {
            Navigator.pop(sheetContext);
            _openEditorSheet(context, initialItem: item);
          },
          onDelete: () {
            Navigator.pop(sheetContext);
            setState(() => _items.remove(item));
            _showSnackBar(context, '已刪除 ${item.title}');
          },
        );
      },
    );
  }

  Future<void> _openEditorSheet(
    BuildContext context, {
    SplitItem? initialItem,
    String? presetGroupMode,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _SplitEditorSheet(
        initialItem: initialItem,
        presetGroupMode: presetGroupMode,
        onSave: (item) {
          setState(() {
            if (initialItem == null) {
              _items.insert(0, item);
            } else {
              final index = _items.indexOf(initialItem);
              if (index >= 0) {
                _items[index] = item;
              } else {
                _items.insert(0, item);
              }
            }
          });
          _showSnackBar(
            context,
            initialItem == null ? '已新增分帳：${item.title}' : '已更新分帳：${item.title}',
          );
        },
      ),
    );
  }

  double _parseAmount(String amountText) {
    return double.tryParse(amountText.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SplitSummaryCard extends StatelessWidget {
  const _SplitSummaryCard({
    required this.groupCount,
    required this.payableTotal,
    required this.receivableTotal,
    required this.syncedCount,
    required this.confirmedCount,
  });

  final int groupCount;
  final double payableTotal;
  final double receivableTotal;
  final int syncedCount;
  final int confirmedCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('分帳總覽', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '$groupCount 個群組',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatChip(
                  label: '待付',
                  value: payableTotal,
                  color: AppColors.pinkPrimary,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  label: '待收',
                  value: receivableTotal,
                  color: AppColors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatChip(
                  label: '已同步',
                  value: syncedCount.toDouble(),
                  color: AppColors.inkLight,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  label: '已確認',
                  value: confirmedCount.toDouble(),
                  color: AppColors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitGroupActionsCard extends StatelessWidget {
  const _SplitGroupActionsCard({
    required this.groupCount,
    required this.memberCount,
    required this.onCreateGroup,
    required this.onJoinGroup,
  });

  final int groupCount;
  final int memberCount;
  final VoidCallback onCreateGroup;
  final VoidCallback onJoinGroup;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('親友群組', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '$groupCount 個群組・$memberCount 位成員',
              style: const TextStyle(color: AppColors.inkLight),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCreateGroup,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('建立群組'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onJoinGroup,
                    icon: const Icon(Icons.group_add),
                    label: const Text('加入群組'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitDetailSheet extends StatelessWidget {
  const _SplitDetailSheet({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final SplitItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              item.subtitle,
              style: const TextStyle(color: AppColors.inkLight),
            ),
            const SizedBox(height: 18),
            _DetailRow(label: '群組模式', value: item.groupMode),
            _DetailRow(label: '金額', value: item.amount),
            _DetailRow(label: '圖示', value: _splitIconName(item.icon)),
            _DetailRow(label: '成員', value: item.memberSummary),
            _DetailRow(label: '比例', value: item.proportionSummary),
            _DetailRow(
              label: '確認通知',
              value: item.confirmationSent ? '已發送' : '待發送',
            ),
            _DetailRow(
              label: '同步記帳',
              value: item.syncedToLedger ? '已同步' : '尚未同步',
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onEdit,
                    child: const Text('編輯'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onDelete,
                    child: const Text('刪除'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitEditorSheet extends StatefulWidget {
  const _SplitEditorSheet({
    required this.onSave,
    this.initialItem,
    this.presetGroupMode,
  });

  final SplitItem? initialItem;
  final String? presetGroupMode;
  final ValueChanged<SplitItem> onSave;

  @override
  State<_SplitEditorSheet> createState() => _SplitEditorSheetState();
}

class _SplitEditorSheetState extends State<_SplitEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _amountController;
  late final TextEditingController _membersController;
  late final TextEditingController _proportionsController;
  late final TextEditingController _groupNameController;
  late String _selectedStatus;
  late String _selectedIconName;
  late String _selectedGroupMode;
  late bool _syncToLedger;
  late bool _sendConfirmation;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialItem?.title ?? '',
    );
    _subtitleController = TextEditingController(
      text: widget.initialItem?.subtitle ?? '',
    );
    _amountController = TextEditingController(
      text: _extractAmount(widget.initialItem?.amount ?? ''),
    );
    _membersController = TextEditingController(
      text: widget.initialItem?.members.isNotEmpty == true
          ? widget.initialItem!.members.join(', ')
          : '我, 朋友A, 朋友B',
    );
    _proportionsController = TextEditingController(
      text: widget.initialItem?.proportions.isNotEmpty == true
          ? widget.initialItem!.proportions
                .map((value) => (value * 100).toStringAsFixed(0))
                .join(', ')
          : '50, 25, 25',
    );
    _groupNameController = TextEditingController(
      text: widget.initialItem?.title ?? '',
    );
    _selectedStatus = widget.initialItem?.amount.startsWith('待收') == true
        ? '待收'
        : '待付';
    _selectedIconName = widget.initialItem != null
        ? _splitIconName(widget.initialItem!.icon)
        : '群組';
    _selectedGroupMode =
        widget.presetGroupMode ?? widget.initialItem?.groupMode ?? '建立群組';
    _syncToLedger = widget.initialItem?.syncedToLedger ?? true;
    _sendConfirmation = widget.initialItem?.confirmationSent ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _amountController.dispose();
    _membersController.dispose();
    _proportionsController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                widget.initialItem == null ? '新增分帳' : '編輯分帳',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '可建立或加入親友群組，並設定每位成員的分攤比例。',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.inkLight),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                children: [
                  ChoiceChip(
                    label: const Text('建立群組'),
                    selected: _selectedGroupMode == '建立群組',
                    onSelected: (_) => setState(() {
                      _selectedGroupMode = '建立群組';
                    }),
                  ),
                  ChoiceChip(
                    label: const Text('加入群組'),
                    selected: _selectedGroupMode == '加入群組',
                    onSelected: (_) => setState(() {
                      _selectedGroupMode = '加入群組';
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  labelText: '群組名稱',
                  hintText: '例如：京都旅行',
                ),
                maxLength: 20,
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return '請輸入群組名稱';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subtitleController,
                decoration: const InputDecoration(
                  labelText: '描述',
                  hintText: '例如：3 位朋友 - 晚餐與計程車',
                ),
                maxLines: 2,
                maxLength: 80,
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return '請輸入描述';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _membersController,
                decoration: const InputDecoration(
                  labelText: '成員名單',
                  hintText: '例如：我, 小安, 阿哲',
                ),
                maxLines: 2,
                maxLength: 80,
                validator: (value) {
                  if (_splitCsv(value).length < 2) {
                    return '至少要有 2 位成員';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _proportionsController,
                decoration: const InputDecoration(
                  labelText: '分攤比例(%)',
                  hintText: '例如：40, 30, 30',
                ),
                maxLength: 80,
                validator: (value) {
                  final members = _splitCsv(_membersController.text);
                  final proportions = _splitPercentages(value);
                  if (proportions.isEmpty) {
                    return '請輸入比例';
                  }
                  if (proportions.length != members.length) {
                    return '比例數量需和成員數相同';
                  }
                  final total = proportions.fold<double>(
                    0,
                    (sum, item) => sum + item,
                  );
                  if ((total - 100).abs() > 0.5) {
                    return '比例加總需等於 100%';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('待付'),
                      selected: _selectedStatus == '待付',
                      onSelected: (_) => setState(() => _selectedStatus = '待付'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('待收'),
                      selected: _selectedStatus == '待收',
                      onSelected: (_) => setState(() => _selectedStatus = '待收'),
                    ),
                  ),
                ],
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
                  hintText: '例如 46',
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
              DropdownButtonFormField<String>(
                key: ValueKey(_selectedIconName),
                initialValue: _selectedIconName,
                decoration: const InputDecoration(labelText: '圖示'),
                items: const [
                  DropdownMenuItem(value: '群組', child: Text('群組')),
                  DropdownMenuItem(value: '旅行', child: Text('旅行')),
                  DropdownMenuItem(value: '採買', child: Text('採買')),
                  DropdownMenuItem(value: '咖啡', child: Text('咖啡')),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _selectedIconName = value);
                },
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _syncToLedger,
                onChanged: (value) => setState(() => _syncToLedger = value),
                title: const Text('同步到個人記帳'),
                subtitle: const Text('送出後會自動加入記帳清單'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _sendConfirmation,
                onChanged: (value) => setState(() => _sendConfirmation = value),
                title: const Text('送出確認通知'),
                subtitle: const Text('模擬通知群組其他成員確認帳款細節'),
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

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final title = _groupNameController.text.trim();
    final subtitle = _subtitleController.text.trim();
    final amount = double.parse(
      _amountController.text.trim().replaceAll(',', ''),
    );
    final members = _splitCsv(_membersController.text);
    final proportions = _splitPercentages(
      _proportionsController.text,
    ).map((value) => value / 100).toList();
    final amountLabel =
        '${_selectedStatus == '待付' ? '待付' : '待收'} \$${_formatSplitAmount(amount)}';

    final item = SplitItem(
      title: title,
      subtitle: subtitle,
      amount: amountLabel,
      icon: _splitIconForName(_selectedIconName),
      groupMode: _selectedGroupMode,
      members: members,
      proportions: proportions,
      syncedToLedger: _syncToLedger,
      confirmationSent: _sendConfirmation,
    );

    final confirmed = await _confirmSplitSave(item);
    if (!confirmed) {
      return;
    }

    if (!mounted) {
      return;
    }

    widget.onSave(item);

    if (_syncToLedger) {
      ledgerItems.insert(
        0,
        LedgerItem(
          title: title,
          subtitle: '$subtitle · ${members.join('、')}',
          amount: _selectedStatus == '待收'
              ? '+\$${_formatSplitLedgerAmount(amount)}'
              : '-\$${_formatSplitLedgerAmount(amount)}',
          isIncome: _selectedStatus == '待收',
          icon: _selectedStatus == '待收' ? Icons.payments : Icons.receipt_long,
          recordedAt: DateTime.now(),
        ),
      );
    }

    Navigator.pop(context);
  }

  Future<bool> _confirmSplitSave(SplitItem item) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('確認分帳內容'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('群組：${item.title}'),
                const SizedBox(height: 6),
                Text('成員：${item.memberSummary}'),
                const SizedBox(height: 6),
                Text('比例：${item.proportionSummary}'),
                const SizedBox(height: 6),
                Text('金額：${item.amount}'),
                const SizedBox(height: 6),
                Text('同步記帳：${item.syncedToLedger ? '是' : '否'}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('確認送出'),
              ),
            ],
          ),
        ) ??
        false;
  }

  List<String> _splitCsv(String? value) {
    return (value ?? '')
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<double> _splitPercentages(String? value) {
    return (value ?? '')
        .split(',')
        .map((item) => double.tryParse(item.trim()) ?? -1)
        .where((item) => item >= 0)
        .toList();
  }
}

String _extractAmount(String amountText) {
  return amountText.replaceAll(RegExp(r'[^0-9.]'), '');
}

String _formatSplitAmount(double value) {
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

String _formatSplitLedgerAmount(double value) {
  final fixed = value.toStringAsFixed(0);
  return fixed.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
}

String _splitIconName(IconData icon) {
  return switch (icon) {
    Icons.flight_takeoff => '旅行',
    Icons.shopping_cart => '採買',
    Icons.group => '群組',
    Icons.local_cafe => '咖啡',
    _ => '群組',
  };
}

IconData _splitIconForName(String name) {
  return switch (name) {
    '旅行' => Icons.flight_takeoff,
    '採買' => Icons.shopping_cart,
    '咖啡' => Icons.local_cafe,
    _ => Icons.group,
  };
}
