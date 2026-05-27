part of '../main.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  final List<GoalItem> _goals = goalItems;

  List<GoalItem> get _achievedGoals =>
      _goals.where((goal) => goal.isAchieved).toList();

  double get _totalTarget =>
      _goals.fold<double>(0, (sum, item) => sum + item.targetAmount);

  double get _totalSaved =>
      _goals.fold<double>(0, (sum, item) => sum + item.savedAmount);

  double get _overallProgress {
    if (_totalTarget <= 0) {
      return 0;
    }
    return _totalSaved / _totalTarget;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _PageScaffold(
          title: '目標',
          subtitle: '把想買的東西、金額和期限先記下來。',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _GoalSummaryCard(
                totalSaved: _totalSaved,
                totalTarget: _totalTarget,
                completionRate: _overallProgress,
                goalCount: _goals.length,
              ),
              const SizedBox(height: 20),
              _SectionHeader(title: '目標紀錄'),
              const SizedBox(height: 12),
              if (_goals.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: const [
                        Icon(Icons.flag_rounded, color: AppColors.inkLight),
                        SizedBox(width: 12),
                        Expanded(child: Text('還沒有任何目標，先按右下角新增一個。')),
                      ],
                    ),
                  ),
                )
              else
                ..._goals.map(
                  (item) => GoalTile(
                    item: item,
                    onTap: () => _openGoalDetail(context, item),
                  ),
                ),
              const SizedBox(height: 20),
              _SectionHeader(title: '目標成就表'),
              const SizedBox(height: 12),
              if (_achievedGoals.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: const [
                        Icon(Icons.emoji_events, color: AppColors.inkLight),
                        SizedBox(width: 12),
                        Expanded(child: Text('目前還沒有完成的目標。')),
                      ],
                    ),
                  ),
                )
              else
                ..._achievedGoals.map(
                  (goal) => _GoalAchievementTile(goal: goal),
                ),
            ],
          ),
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: SafeArea(
            child: FloatingActionButton(
              onPressed: () => _openGoalEditor(context),
              backgroundColor: AppColors.pinkPrimary,
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    );
  }

  void _openGoalDetail(BuildContext context, GoalItem goal) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return _GoalDetailSheet(
          goal: goal,
          onEdit: () {
            Navigator.pop(sheetContext);
            _openGoalEditor(context, initialGoal: goal);
          },
          onDelete: () {
            Navigator.pop(sheetContext);
            setState(() => _goals.remove(goal));
            _showSnackBar(context, '已刪除 ${goal.title}');
          },
          onAdjust: (delta) {
            Navigator.pop(sheetContext);
            _applyGoalAdjustment(goal, delta);
          },
        );
      },
    );
  }

  Future<void> _openGoalEditor(
    BuildContext context, {
    GoalItem? initialGoal,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _GoalEditorSheet(
        initialGoal: initialGoal,
        onSave: (goal) {
          setState(() {
            if (initialGoal == null) {
              _goals.insert(0, goal);
            } else {
              final index = _goals.indexOf(initialGoal);
              if (index >= 0) {
                _goals[index] = goal;
              } else {
                _goals.insert(0, goal);
              }
            }
          });
          _showSnackBar(
            context,
            initialGoal == null ? '已新增目標：${goal.title}' : '已更新目標：${goal.title}',
          );
        },
      ),
    );
  }

  void _applyGoalAdjustment(GoalItem goal, double delta) {
    setState(() {
      final index = _goals.indexOf(goal);
      if (index < 0) {
        return;
      }

      final updatedSavedAmount = _goals[index].savedAmount + delta;
      final reachedTarget = updatedSavedAmount >= _goals[index].targetAmount;
      final updatedGoal = _goals[index].copyWith(
        savedAmount: updatedSavedAmount < 0 ? 0 : updatedSavedAmount,
        achievedAt: reachedTarget
            ? (_goals[index].achievedAt ?? DateTime.now())
            : _goals[index].achievedAt,
      );
      _goals[index] = updatedGoal;
    });

    _showSnackBar(context, '${delta >= 0 ? '增加' : '減少'}目標進度：${goal.title}');
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _GoalSummaryCard extends StatelessWidget {
  const _GoalSummaryCard({
    required this.totalSaved,
    required this.totalTarget,
    required this.completionRate,
    required this.goalCount,
  });

  final double totalSaved;
  final double totalTarget;
  final double completionRate;
  final int goalCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('目標總覽', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '\$${totalSaved.toStringAsFixed(0)} / \$${totalTarget.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatChip(
                  label: '已存',
                  value: totalSaved,
                  color: AppColors.green,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  label: '目標',
                  value: totalTarget,
                  color: AppColors.pinkPrimary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: completionRate.clamp(0.0, 1.0).toDouble(),
                minHeight: 10,
                backgroundColor: AppColors.pinkSoft,
                valueColor: const AlwaysStoppedAnimation(AppColors.pinkPrimary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$goalCount 個目標・完成率 ${(completionRate * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: AppColors.inkLight),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalAchievementTile extends StatelessWidget {
  const _GoalAchievementTile({required this.goal});

  final GoalItem goal;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.green.withValues(alpha: 0.15),
          child: const Icon(Icons.emoji_events, color: AppColors.green),
        ),
        title: Text(goal.title),
        subtitle: Text('${goal.description}\n達成日期：${goal.achievedAtLabel}'),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              goal.targetAmountLabel,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              '已達成',
              style: TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalDetailSheet extends StatefulWidget {
  const _GoalDetailSheet({
    required this.goal,
    required this.onEdit,
    required this.onDelete,
    required this.onAdjust,
  });

  final GoalItem goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<double> onAdjust;

  @override
  State<_GoalDetailSheet> createState() => _GoalDetailSheetState();
}

class _GoalDetailSheetState extends State<_GoalDetailSheet> {
  late final TextEditingController _amountController;
  final GlobalKey<FormState> _adjustFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: '100');
  }

  @override
  void dispose() {
    _amountController.dispose();
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
        key: _adjustFormKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.goal.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                widget.goal.description,
                style: const TextStyle(color: AppColors.inkLight),
              ),
              const SizedBox(height: 18),
              _DetailRow(label: '期限', value: widget.goal.deadlineLabel),
              _DetailRow(label: '目標金額', value: widget.goal.targetAmountLabel),
              _DetailRow(label: '目前已存', value: widget.goal.savedAmountLabel),
              _DetailRow(label: '還差', value: widget.goal.remainingAmountLabel),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: widget.goal.progress,
                  minHeight: 10,
                  backgroundColor: AppColors.pinkSoft,
                  valueColor: const AlwaysStoppedAnimation(
                    AppColors.pinkPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('目前進度 ${widget.goal.progressLabel}'),
              const SizedBox(height: 18),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: '調整金額',
                  hintText: '例如 100',
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
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _increaseProgress,
                      icon: const Icon(Icons.add),
                      label: const Text('增加進度'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _decreaseProgress,
                      icon: const Icon(Icons.remove),
                      label: const Text('減少進度'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onEdit,
                      child: const Text('編輯'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onDelete,
                      child: const Text('刪除'),
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

  void _increaseProgress() {
    if (!(_adjustFormKey.currentState?.validate() ?? false)) {
      return;
    }

    final amount = double.parse(
      _amountController.text.trim().replaceAll(',', ''),
    );
    if (amount > widget.goal.remainingAmount &&
        widget.goal.remainingAmount > 0) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('增加金額不可大於剩餘金額。')));
      return;
    }

    Navigator.pop(context);
    widget.onAdjust(amount);
  }

  void _decreaseProgress() {
    if (!(_adjustFormKey.currentState?.validate() ?? false)) {
      return;
    }

    final amount = double.parse(
      _amountController.text.trim().replaceAll(',', ''),
    );
    if (amount > widget.goal.savedAmount) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('減少金額不可大於目前已存。')));
      return;
    }

    Navigator.pop(context);
    widget.onAdjust(-amount);
  }
}

class _GoalEditorSheet extends StatefulWidget {
  const _GoalEditorSheet({required this.onSave, this.initialGoal});

  final GoalItem? initialGoal;
  final ValueChanged<GoalItem> onSave;

  @override
  State<_GoalEditorSheet> createState() => _GoalEditorSheetState();
}

class _GoalEditorSheetState extends State<_GoalEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _targetAmountController;
  late final TextEditingController _savedAmountController;
  late DateTime _deadline;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialGoal?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialGoal?.description ?? '',
    );
    _targetAmountController = TextEditingController(
      text: widget.initialGoal?.targetAmount.toStringAsFixed(0) ?? '',
    );
    _savedAmountController = TextEditingController(
      text: widget.initialGoal?.savedAmount.toStringAsFixed(0) ?? '0',
    );
    _deadline =
        widget.initialGoal?.deadline ??
        DateTime.now().add(const Duration(days: 90));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    _savedAmountController.dispose();
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
                widget.initialGoal == null ? '新增目標' : '編輯目標',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '把想買的東西、金額和期限先記起來。',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.inkLight),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '目標名稱',
                  hintText: '例如：相機基金',
                ),
                maxLength: 20,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return '請輸入目標名稱';
                  }
                  return null;
                },
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
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return '請輸入目標描述';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _targetAmountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: '目標金額',
                  hintText: '例如 1200',
                  prefixText: '\$',
                ),
                validator: (value) {
                  final amount = double.tryParse(
                    (value ?? '').trim().replaceAll(',', ''),
                  );
                  if (amount == null) {
                    return '請輸入數字';
                  }
                  if (amount <= 0) {
                    return '目標金額必須大於 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _savedAmountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: '目前已存',
                  hintText: '例如 600',
                  prefixText: '\$',
                ),
                validator: (value) {
                  final savedAmount = double.tryParse(
                    (value ?? '').trim().replaceAll(',', ''),
                  );
                  final targetAmount = double.tryParse(
                    _targetAmountController.text.trim().replaceAll(',', ''),
                  );
                  if (savedAmount == null) {
                    return '請輸入數字';
                  }
                  if (savedAmount < 0) {
                    return '已存金額不能小於 0';
                  }
                  if (targetAmount != null && savedAmount > targetAmount) {
                    return '已存金額不能大於目標金額';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(labelText: '截止日期'),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_deadline.year}/${_deadline.month}/${_deadline.day}',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final today = DateUtils.dateOnly(DateTime.now());
                        final initialDate = _deadline.isBefore(today)
                            ? today
                            : _deadline;
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: initialDate,
                          firstDate: today,
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );
                        if (selected != null) {
                          setState(() => _deadline = selected);
                        }
                      },
                      child: const Text('選日期'),
                    ),
                  ],
                ),
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
    final description = _descriptionController.text.trim();
    final targetAmount = double.tryParse(
      _targetAmountController.text.trim().replaceAll(',', ''),
    );
    final savedAmount =
        double.tryParse(
          _savedAmountController.text.trim().replaceAll(',', ''),
        ) ??
        0;

    if (title.isEmpty ||
        description.isEmpty ||
        targetAmount == null ||
        targetAmount <= 0 ||
        savedAmount < 0) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('請輸入完整且正確的目標資料。')));
      return;
    }

    widget.onSave(
      GoalItem(
        title: title,
        description: description,
        targetAmount: targetAmount,
        deadline: _deadline,
        savedAmount: savedAmount,
        achievedAt: savedAmount >= targetAmount
            ? (widget.initialGoal?.achievedAt ?? DateTime.now())
            : widget.initialGoal?.achievedAt,
      ),
    );

    Navigator.pop(context);
  }
}
