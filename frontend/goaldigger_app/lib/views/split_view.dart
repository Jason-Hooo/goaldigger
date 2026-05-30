part of '../main.dart';

class GroupDetailPage extends StatefulWidget {
  const GroupDetailPage({
    super.key,
    required this.group,
    required this.user,
  });

  final GroupSummary group;
  final AuthUser user;

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage>
  with RealtimeRefreshMixin<GroupDetailPage> {
  final ApiConnect _api = ApiConnect();
  List<SplitExpense> _expenses = [];
  List<GroupMember> _members = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _hasLoadedOnce = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGroupData();
    watchTables(
      channelName: 'group-detail-${widget.group.groupId}',
      tables: const [
        'group_members',
        'group_consumptions',
        'consumption_participants',
      ],
      onChange: () => _loadGroupData(silent: true),
    );
  }

  Future<void> _loadGroupData({bool silent = false}) async {
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
        _api.fetchSplitExpenses(widget.user.userId),
        _api.getGroupMembers(widget.group.groupId),
      ]);
      final allExpenses = results[0] as List<SplitExpense>;
      final members = results[1] as List<GroupMember>;
      if (!mounted) {
        return;
      }
      setState(() {
        _expenses = allExpenses
            .where((expense) => expense.groupId == widget.group.groupId)
            .toList();
        _members = members;
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

  String _readableError(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return '資料讀取失敗，請稍後再試。';
  }

  SplitExpense _buildOptimisticExpense(_GroupExpenseDraft draft) {
    final participants = draft.splitDetails.map((detail) {
      final userId = detail['user_id'] as int;
      final sharedAmount = (detail['shared_amount'] as num).toDouble();
      final member = _members.firstWhere(
        (entry) => entry.userId == userId,
        orElse: () => GroupMember(userId: userId, userName: '成員'),
      );
      return SplitParticipant(
        userId: userId,
        userName: member.userName,
        sharedAmount: sharedAmount,
        isPayer: userId == draft.payerId,
        status: 'pending',
      );
    }).toList();

    return SplitExpense(
      consumptionId: draft.consumptionId ?? -DateTime.now().microsecondsSinceEpoch,
      groupId: draft.groupId,
      groupName: widget.group.groupName,
      name: draft.name,
      amount: draft.amount,
      createdAt: DateTime.now(),
      participants: participants,
    );
  }

  void _upsertExpense(SplitExpense expense) {
    setState(() {
      final nextExpenses = List<SplitExpense>.from(_expenses);
      final index = nextExpenses.indexWhere((entry) => entry.consumptionId == expense.consumptionId);
      if (index >= 0) {
        nextExpenses[index] = expense;
      } else {
        nextExpenses.insert(0, expense);
      }
      _expenses = nextExpenses;
    });
  }

  void _removeExpense(int consumptionId) {
    setState(() {
      _expenses = _expenses.where((expense) => expense.consumptionId != consumptionId).toList();
    });
  }

  void _showQRCodeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '群組邀請碼',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.pinkPrimary),
              ),
              child: Column(
                children: [
                  Text(
                    widget.group.invitationCode,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  QrImageView(
                    data: widget.group.invitationCode,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(sheetContext),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pinkPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('關閉'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMembersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '群組成員',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_members.length} 人',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_members.isEmpty)
              const Center(
                child: Text('暫無成員', style: TextStyle(color: Colors.grey)),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.pinkPrimary,
                        child: Text(
                          member.userName.isNotEmpty ? member.userName[0] : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(member.userName),
                      subtitle: Text('ID: ${member.userId}'),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(sheetContext),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pinkPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('關閉'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLeaveGroup(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('退出群組'),
        content: const Text('確定要退出此群組嗎？此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _api.leaveGroup(
                  groupId: widget.group.groupId,
                  userId: widget.user.userId,
                );
                if (context.mounted) {
                  Navigator.pop(context); // Go back to split view
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('已退出群組'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('退出群組失敗: $error'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.groupName),
        backgroundColor: AppColors.pinkPrimary,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.people),
              onPressed: () => _showMembersSheet(context),
              tooltip: '群組成員',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.pinkPrimary.withValues(alpha: 0.15),
                child: const Icon(Icons.qr_code, color: AppColors.pinkPrimary),
              ),
              title: const Text('分享邀請碼'),
              subtitle: const Text('顯示 QR Code 讓其他人掃描加入'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showQRCodeSheet(context),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red.withValues(alpha: 0.15),
                child: const Icon(Icons.exit_to_app, color: Colors.red),
              ),
              title: const Text('退出群組'),
              subtitle: const Text('離開此群組'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _confirmLeaveGroup(context),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.pinkPrimary.withValues(alpha: 0.15),
                child: const Icon(Icons.account_balance_wallet, color: AppColors.pinkPrimary),
              ),
              title: const Text('結算建議'),
              subtitle: const Text('查看誰該轉帳給誰'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _openSettlementSheet(context),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _PageScaffold(
              title: '群組帳目',
              subtitle: '此群組的分帳紀錄',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  if (_isRefreshing)
                    const LinearProgressIndicator(minHeight: 2),
                  if (_isRefreshing) const SizedBox(height: 12),
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
                                onPressed: _loadGroupData,
                                child: const Text('重試'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_expenses.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: const [
                            Icon(Icons.receipt_long, color: AppColors.inkLight),
                            SizedBox(width: 12),
                            Expanded(child: Text('還沒有帳目紀錄，按右下角新增一筆。')),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _expenses
                          .map(
                            (expense) => _GroupExpenseTile(
                              expense: expense,
                              currentUserId: widget.user.userId,
                              onTap: () => _openExpenseDetail(context, expense),
                              onDelete: () => _deleteExpense(expense),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-split',
        onPressed: () => _openExpenseEditor(context),
        backgroundColor: AppColors.pinkPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openExpenseDetail(BuildContext context, SplitExpense expense) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return _ExpenseDetailSheet(
          expense: expense,
          currentUserId: widget.user.userId,
          onEdit: () {
            Navigator.pop(sheetContext);
            _openExpenseEditor(context, initialExpense: expense);
          },
          onDelete: () {
            Navigator.pop(sheetContext);
            _deleteExpense(expense);
          },
        );
      },
    );
  }

  Future<void> _deleteExpense(SplitExpense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('刪除帳目'),
        content: Text('確定要刪除「${expense.name}」嗎？\n這個操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.pinkPrimary),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('確認刪除'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final previousExpenses = List<SplitExpense>.from(_expenses);
    _removeExpense(expense.consumptionId);

    try {
      await _api.deleteSplitExpense(expense.consumptionId);
      AppRefreshBus.notifyChanged();
      unawaited(_loadGroupData(silent: true));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('已刪除 ${expense.name}')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _expenses = previousExpenses;
      });
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(_readableError(error))));
    }
  }

  void _openExpenseEditor(BuildContext context, {SplitExpense? initialExpense}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _GroupExpenseEditorSheet(
        group: widget.group,
        currentUserId: widget.user.userId,
        initialExpense: initialExpense,
        onSave: (draft) async {
          _upsertExpense(_buildOptimisticExpense(draft));
          try {
            unawaited(_loadGroupData(silent: true));
          } catch (_) {
            // Background refresh errors are intentionally ignored here.
          }
          if (!mounted) {
            return;
          }
          Navigator.pop(sheetContext);
        },
      ),
    );
  }

  void _openSettlementSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return _SettlementSheet(
          group: widget.group,
          currentUserId: widget.user.userId,
        );
      },
    );
  }
}

class _GroupExpenseTile extends StatelessWidget {
  const _GroupExpenseTile({
    required this.expense,
    required this.currentUserId,
    required this.onTap,
    required this.onDelete,
  });

  final SplitExpense expense;
  final int currentUserId;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final currentUser = expense.participants
        .cast<SplitParticipant?>()
        .firstWhere((p) => p?.userId == currentUserId, orElse: () => null);
    final isPayer = currentUser?.isPayer ?? false;
    final currentShare = currentUser?.sharedAmount ?? 0;

    // 👇 1. 再次把算錢邏輯搬進來
    double receivable = 0;
    double payable = 0;

    if (isPayer) {
      receivable = expense.participants
          .where((p) => p.userId != currentUserId && p.status != 'paid')
          .fold(0.0, (sum, p) => sum + p.sharedAmount);
    } else {
      if (currentUser != null && currentUser.status != 'paid') {
        payable = currentShare;
      }
    }

    // 👇 2. 動態決定要顯示的文字跟顏色
    String statusText;
    Color statusColor;

    if (isPayer) {
      if (receivable > 0) {
        statusText = '待收';
        statusColor = AppColors.green;
      } else {
        statusText = '已收齊'; // 錢收齊了！
        statusColor = const Color.fromARGB(255, 19, 16, 202); // 變成低調的灰色
      }
    } else {
      if (payable > 0) {
        statusText = '待付';
        statusColor = AppColors.pinkPrimary;
      } else {
        statusText = '已還款'; // 錢付清了！
        statusColor = const Color.fromARGB(255, 19, 16, 202); // 變成低調的灰色
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPayer
              ? AppColors.green.withValues(alpha: 0.15)
              : AppColors.pinkPrimary.withValues(alpha: 0.15),
          child: Icon(
            isPayer ? Icons.arrow_upward : Icons.arrow_downward,
            color: isPayer ? AppColors.green : AppColors.pinkPrimary,
          ),
        ),
        title: Text(expense.name),
        subtitle: Text('${expense.createdAt.toString().split('.')[0]} · ${expense.participants.length} 位成員'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${expense.amount.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _ExpenseDetailSheet extends StatefulWidget {
  const _ExpenseDetailSheet({
    required this.expense,
    required this.currentUserId,
    required this.onEdit,
    required this.onDelete,
  });

  final SplitExpense expense;
  final int currentUserId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_ExpenseDetailSheet> createState() => _ExpenseDetailSheetState();
}

class _ExpenseDetailSheetState extends State<_ExpenseDetailSheet> {
  final ApiConnect _api = ApiConnect();
  SplitExpense? _currentExpense;

  @override
  void initState() {
    super.initState();
    _currentExpense = widget.expense;
  }

  Future<void> _confirmRepayment(SplitParticipant participant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('確認還款'),
        content: Text('確定要確認 ${participant.userName} 已經還款 \$${participant.sharedAmount.toStringAsFixed(0)} 嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('確認'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _api.updateParticipantStatus(
        consumptionId: widget.expense.consumptionId,
        userId: participant.userId,
        status: 'paid',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        // Update the participant status locally
        final updatedParticipants = _currentExpense!.participants.map((p) {
          if (p.userId == participant.userId) {
            return SplitParticipant(
              userId: p.userId,
              userName: p.userName,
              sharedAmount: p.sharedAmount,
              isPayer: p.isPayer,
              status: 'paid',
            );
          }
          return p;
        }).toList();
        _currentExpense = SplitExpense(
          consumptionId: _currentExpense!.consumptionId,
          groupId: _currentExpense!.groupId,
          groupName: _currentExpense!.groupName,
          name: _currentExpense!.name,
          amount: _currentExpense!.amount,
          createdAt: _currentExpense!.createdAt,
          participants: updatedParticipants,
        );
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('確認還款失敗: $error'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseToUse = _currentExpense ?? widget.expense;
    final currentUser = expenseToUse.participants
        .cast<SplitParticipant?>()
        .firstWhere((p) => p?.userId == widget.currentUserId, orElse: () => null);
    final isPayer = currentUser?.isPayer ?? false;
    final currentShare = currentUser?.sharedAmount ?? 0;
    final payer = expenseToUse.participants.cast<SplitParticipant?>().firstWhere((p) => p?.isPayer ?? false, orElse: () => null);

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
            Text(expenseToUse.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              expenseToUse.groupName,
              style: const TextStyle(color: AppColors.inkLight),
            ),
            const SizedBox(height: 18),
            _DetailRow(label: '金額', value: '\$${expenseToUse.amount.toStringAsFixed(0)}'),
            _DetailRow(label: '建立時間', value: expenseToUse.createdAt.toString().split('.')[0]),
            _DetailRow(label: '成員數', value: '${expenseToUse.participants.length} 人'),
            if (payer != null)
              _DetailRow(label: '代墊者', value: payer.userName),
            _DetailRow(
              label: '你的角色',
              value: isPayer ? '代墊者' : '分攤者',
            ),
            _DetailRow(
              label: isPayer ? '待收金額' : '待付金額',
              value: '\$${currentShare.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 18),
            const Text(
              '分攤明細',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...expenseToUse.participants.map((participant) {
              final participantStatus = participant.status ?? 'pending';
              final canConfirmRepayment = isPayer && !participant.isPayer && participantStatus == 'pending';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: participant.isPayer
                          ? AppColors.pinkPrimary
                          : AppColors.pinkPrimary.withValues(alpha: 0.3),
                      child: Text(
                        participant.userName.isNotEmpty ? participant.userName[0] : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            participant.userName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (participant.isPayer)
                            const Text(
                              '代墊者',
                              style: TextStyle(fontSize: 12, color: AppColors.pinkPrimary),
                            ),
                          if (!participant.isPayer && participantStatus == 'paid')
                            const Text(
                              '已還款',
                              style: TextStyle(fontSize: 12, color: Colors.green),
                            ),
                        ],
                      ),
                    ),
                    if (canConfirmRepayment)
                      TextButton(
                        onPressed: () => _confirmRepayment(participant),
                        child: const Text(
                          '確認還款',
                          style: TextStyle(color: AppColors.pinkPrimary),
                        ),
                      ),
                    Text(
                      '\$${participant.sharedAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 18),
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
    );
  }
}

class _GroupExpenseEditorSheet extends StatefulWidget {
  const _GroupExpenseEditorSheet({
    required this.group,
    required this.currentUserId,
    this.initialExpense,
    required this.onSave,
  });

  final GroupSummary group;
  final int currentUserId;
  final SplitExpense? initialExpense;
  final Future<void> Function(_GroupExpenseDraft) onSave;

  @override
  State<_GroupExpenseEditorSheet> createState() => _GroupExpenseEditorSheetState();
}

class _GroupExpenseEditorSheetState extends State<_GroupExpenseEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ApiConnect _api = ApiConnect();
  bool _isLoading = true;
  String? _errorMessage;
  String? _validationError;
  List<GroupMember> _members = [];
  final Map<int, TextEditingController> _memberAmountControllers = {};
  List<ExpenseType> _expenseTypes = [];
  int? _selectedTypeId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialExpense?.name ?? '',
    );
    _amountController = TextEditingController(
      text: widget.initialExpense?.amount.toStringAsFixed(0) ?? '',
    );
    _loadGroupMembers();
    _loadExpenseTypes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    for (final controller in _memberAmountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadGroupMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final members = await _api.getGroupMembers(widget.group.groupId);
      if (!mounted) {
        return;
      }
      setState(() {
        _members = members;
        _initializeMemberControllers();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _initializeMemberControllers() {
    if (widget.initialExpense != null) {
      for (final participant in widget.initialExpense!.participants) {
        _memberAmountControllers[participant.userId] = TextEditingController(
          text: participant.sharedAmount.toStringAsFixed(0),
        );
      }
    } else {
      for (final member in _members) {
        _memberAmountControllers[member.userId] = TextEditingController();
      }
    }
  }

  Future<void> _loadExpenseTypes() async {
    try {
      final allTypes = await _api.getExpenseTypes();
      if (!mounted) {
        return;
      }
      // Filter to show only predefined expense categories (user_id IS NULL and is_expense = true)
      final predefinedExpenseTypes = allTypes.where((type) => !type.isCustom && type.isExpense).toList();
      setState(() {
        _expenseTypes = predefinedExpenseTypes;
      });
    } catch (error) {
      // Don't show error for expense types loading, it's not critical
    }
  }

  void _setEqualSplit() {
    final amount = double.tryParse(_amountController.text.trim().replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      return;
    }
    final equalAmount = (amount / _members.length).toStringAsFixed(0);
    for (final member in _members) {
      _memberAmountControllers[member.userId]?.text = equalAmount;
    }
  }

  double _getTotalMemberAmount() {
    double total = 0;
    for (final controller in _memberAmountControllers.values) {
      final value = double.tryParse(controller.text.trim().replaceAll(',', ''));
      if (value != null) {
        total += value;
      }
    }
    return total;
  }

  Future<void> _save() async {
    setState(() {
      _validationError = null;
    });

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final name = _nameController.text.trim();
    final amount = double.parse(_amountController.text.trim().replaceAll(',', ''));
    final totalMemberAmount = _getTotalMemberAmount();

    if ((totalMemberAmount - amount).abs() > 0.5) {
      setState(() {
        _validationError = '成員分攤金額總和必須等於總金額';
      });
      return;
    }

    final splitDetails = <Map<String, dynamic>>[];
    for (final member in _members) {
      final controller = _memberAmountControllers[member.userId];
      final sharedAmount = double.tryParse(controller?.text.trim().replaceAll(',', '') ?? '0') ?? 0;
      splitDetails.add({
        'user_id': member.userId,
        'shared_amount': sharedAmount,
      });
    }

    try {
      if (widget.initialExpense != null) {
        await ApiConnect().updateSplitExpense(
          consumptionId: widget.initialExpense!.consumptionId,
          groupId: widget.group.groupId,
          name: name,
          amount: amount,
          payerId: widget.currentUserId,
          typeId: _selectedTypeId,
          splitDetails: splitDetails,
        );
      } else {
        await ApiConnect().addSplitExpense(
          groupId: widget.group.groupId,
          name: name,
          amount: amount,
          payerId: widget.currentUserId,
          typeId: _selectedTypeId,
          splitDetails: splitDetails,
        );
      }
      AppRefreshBus.notifyChanged();
      await widget.onSave(
        _GroupExpenseDraft(
          consumptionId: widget.initialExpense?.consumptionId,
          groupId: widget.group.groupId,
          name: name,
          amount: amount,
          payerId: widget.currentUserId,
          typeId: _selectedTypeId,
          splitDetails: splitDetails,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _validationError = error.toString();
      });
    }
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
                widget.initialExpense == null ? '新增群組帳目' : '編輯群組帳目',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '為 ${widget.group.groupName} 新增一筆分帳紀錄',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.inkLight),
              ),
              const SizedBox(height: 16),
              if (_validationError != null)
                Card(
                  color: Colors.red.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _validationError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_validationError != null) const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '帳目名稱',
                  hintText: '例如：晚餐',
                ),
                maxLength: 20,
                onChanged: (_) => setState(() => _validationError = null),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return '請輸入帳目名稱';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '總金額',
                  prefixText: '\$',
                  hintText: '例如 500',
                ),
                onChanged: (_) => setState(() => _validationError = null),
                validator: (value) {
                  final amount = double.tryParse((value ?? '').trim().replaceAll(',', ''));
                  if (amount == null) {
                    return '請輸入數字';
                  }
                  if (amount <= 0) {
                    return '金額必須大於 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedTypeId,
                decoration: const InputDecoration(
                  labelText: '支出類別',
                  hintText: '選擇類別',
                ),
                items: _expenseTypes.map((type) {
                  return DropdownMenuItem<int>(
                    value: type.id,
                    child: Text(type.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTypeId = value;
                    _validationError = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              Text(
                '分攤金額',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_errorMessage != null)
                Card(
                  color: AppColors.pinkSoft,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_errorMessage!),
                  ),
                )
              else
                ..._members.map((member) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(member.userName),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 120,
                          child: TextFormField(
                            controller: _memberAmountControllers[member.userId],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              prefixText: '\$',
                              hintText: '0',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onChanged: (_) => setState(() => _validationError = null),
                            validator: (value) {
                              final amount = double.tryParse((value ?? '').trim().replaceAll(',', ''));
                              if (amount == null) {
                                return '請輸入數字';
                              }
                              if (amount < 0) {
                                return '金額不能為負數';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '總計: \$${_getTotalMemberAmount().toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  ActionChip(
                    label: const Text('平均分攤'),
                    onPressed: _setEqualSplit,
                  ),
                ],
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
}

class SplitPage extends StatefulWidget {
  const SplitPage({super.key, required this.user});

  final AuthUser user;

  @override
  State<SplitPage> createState() => _SplitPageState();
}

class _SplitPageState extends State<SplitPage> {
  final ApiConnect _api = ApiConnect();
  List<SplitItem> _items = [];
  List<GroupSummary> _groups = [];

  int get _syncedCount => _items.where((item) => item.syncedToLedger).length;

  int get _confirmedCount =>
      _items.where((item) => item.confirmationSent).length;

  @override
  void initState() {
    super.initState();
    _loadSplits();
  }

  Future<void> _loadSplits() async {
    try {
      final results = await Future.wait([
        _api.fetchGroups(widget.user.userId),
        _api.fetchSplitExpenses(widget.user.userId),
      ]);
      final groups = results[0] as List<GroupSummary>;
      final expenses = results[1] as List<SplitExpense>;
      if (!mounted) {
        return;
      }
      setState(() {
        _groups = groups;
        _items = expenses
            .map((expense) => _mapSplitItem(expense, widget.user.userId))
            .toList();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(_readableError(error))));
    }
  }

  SplitItem _mapSplitItem(SplitExpense expense, int currentUserId) {
    final participants = expense.participants;
    final memberNames = participants.map((p) => p.userName).toList();
    final proportions = participants.isEmpty
        ? const <double>[]
        : participants
            .map<double>(
              (p) => expense.amount == 0 ? 0.0 : p.sharedAmount / expense.amount,
            )
            .toList();

    final current = participants
        .cast<SplitParticipant?>()
        .firstWhere((p) => p?.userId == currentUserId, orElse: () => null);

    final isPayer = current?.isPayer ?? false;
    final currentShare = current?.sharedAmount ?? 0;

    double receivable = 0;
    double payable = 0;

    if (isPayer) {
      // 待收：所有「不是我」且「尚未還款 (status != 'paid')」的金額加總
      receivable = participants
          .where((p) => p.userId != currentUserId && p.status != 'paid')
          .fold(0.0, (sum, p) => sum + p.sharedAmount);
    } else {
      // 待付：如果我還沒還款，待付就是我的份額；如果已經還了，就是 0
      if (current != null && current.status != 'paid') {
        payable = currentShare;
      }
    }

    final amountLabel = isPayer
        ? '待收 \$${_formatSplitAmount(receivable)}'
        : '待付 \$${_formatSplitAmount(payable)}';

    return SplitItem(
      consumptionId: expense.consumptionId,
      groupId: expense.groupId,
      title: expense.groupName,
      subtitle: '${expense.name} · ${memberNames.length} 位成員',
      amount: amountLabel,
      icon: _splitIconForName('群組'),
      groupMode: '群組',
      members: memberNames,
      proportions: proportions,
      syncedToLedger: true,
      confirmationSent: false,
    );
  }

  String _readableError(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return '資料讀取失敗，請稍後再試。';
  }

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
              _SectionHeader(title: '我的群組'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _openEditorSheet(context, presetGroupMode: '建立群組'),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('建立群組'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _openEditorSheet(context, presetGroupMode: '加入群組'),
                      icon: const Icon(Icons.group_add),
                      label: const Text('加入群組'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_groups.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: const [
                        Icon(Icons.group_add, color: AppColors.inkLight),
                        SizedBox(width: 12),
                        Expanded(child: Text('還沒有群組，先建立一個吧。')),
                      ],
                    ),
                  ),
                )
              else
                ..._groups.map(
                  (group) => _GroupCard(
                    group: group,
                    onTap: () => _openGroupDetail(context, group),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _uniqueGroupTitles() {
    final titles = <String>{};
    for (final group in _groups) {
      titles.add(group.groupName);
    }
    return titles.toList();
  }

  void _openGroupDetail(BuildContext context, GroupSummary group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailPage(
          group: group,
          user: widget.user,
        ),
      ),
    ).then((_) => _loadSplits());
  }

  Future<void> _openEditorSheet(
    BuildContext context, {
    String? presetGroupMode,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _GroupEditorSheet(
        availableGroups: _groups,
        currentUserId: widget.user.userId,
        presetGroupMode: presetGroupMode,
        onSave: (draft) async {
          await _submitGroup(draft);
          if (mounted) {
            Navigator.pop(sheetContext);
          }
        },
      ),
    );
  }

  Future<void> _submitGroup(_GroupDraft draft) async {
    try {
      if (draft.groupMode == '建立群組') {
        // When creating, only add the current user
        final createdGroup = await _api.createGroup(
          groupName: draft.groupName,
          userIds: [widget.user.userId],
        );
        if (mounted) {
          setState(() {
            _groups = [
              createdGroup,
              ..._groups.where((group) => group.groupId != createdGroup.groupId),
            ];
          });
        }
      } else {
        if (draft.invitationCode == null) {
          _showSnackBar(context, '請輸入邀請碼');
          return;
        }
        // When joining, use invitation code
        await _api.joinGroupByCode(
          invitationCode: draft.invitationCode!,
          userId: widget.user.userId,
        );
        await _loadSplits();
      }

      if (!mounted) {
        return;
      }
      _showSnackBar(context, draft.groupMode == '建立群組' ? '已建立群組' : '已加入群組');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(context, _readableError(error));
    }
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
          ],
        ),
      ),
    );
  }
}

class _GroupDraft {
  const _GroupDraft({
    required this.groupMode,
    this.groupId,
    this.invitationCode,
    required this.groupName,
    required this.memberIds,
  });

  final String groupMode;
  final int? groupId;
  final String? invitationCode;
  final String groupName;
  final List<int> memberIds;
}

class _GroupExpenseDraft {
  const _GroupExpenseDraft({
    this.consumptionId,
    required this.groupId,
    required this.name,
    required this.amount,
    required this.payerId,
    this.typeId,
    required this.splitDetails,
  });

  final int? consumptionId;
  final int groupId;
  final String name;
  final double amount;
  final int payerId;
  final int? typeId;
  final List<Map<String, dynamic>> splitDetails;
}

class _GroupEditorSheet extends StatefulWidget {
  const _GroupEditorSheet({
    required this.availableGroups,
    required this.currentUserId,
    this.presetGroupMode,
    required this.onSave,
  });

  final String? presetGroupMode;
  final Future<void> Function(_GroupDraft) onSave;
  final List<GroupSummary> availableGroups;
  final int currentUserId;

  @override
  State<_GroupEditorSheet> createState() => _GroupEditorSheetState();
}

class _GroupEditorSheetState extends State<_GroupEditorSheet> {
  late final TextEditingController _groupNameController;
  late final TextEditingController _membersController;
  late final TextEditingController _invitationCodeController;
  late String _selectedGroupMode;
  int? _selectedGroupId;
  String? _selectedInvitationCode;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _groupNameController = TextEditingController();
    _membersController = TextEditingController(
      text: '${widget.currentUserId}, 2, 3',
    );
    _invitationCodeController = TextEditingController();
    _selectedGroupMode = widget.presetGroupMode ?? '建立群組';
    _selectedGroupId = null;
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _membersController.dispose();
    _invitationCodeController.dispose();
    super.dispose();
  }

  List<int> _parseMemberIds(String? text) {
    if (text == null || text.isEmpty) {
      return [];
    }
    return text
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toList();
  }

  void _showQRScanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('掃描 QR Code'),
            backgroundColor: AppColors.pinkPrimary,
            foregroundColor: Colors.white,
          ),
          body: Stack(
            children: [
              MobileScanner(
                onDetect: (capture) {
                  final String? code = capture.barcodes.first.rawValue;
                  if (code != null) {
                    // Extract 6-character alphanumeric code from the scanned text
                    final RegExp codePattern = RegExp(r'[A-Z0-9]{6}');
                    final match = codePattern.firstMatch(code.toUpperCase());
                    if (match != null) {
                      Navigator.pop(context, match.group(0));
                    }
                  }
                },
                errorBuilder: (context, error, child) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '相機無法啟動',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '請手動輸入邀請碼',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.pinkPrimary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('返回'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        children: [
                          // Top-left corner
                          Positioned(
                            top: 0,
                            left: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: AppColors.pinkPrimary, width: 4),
                                  left: BorderSide(color: AppColors.pinkPrimary, width: 4),
                                ),
                              ),
                            ),
                          ),
                          // Top-right corner
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: AppColors.pinkPrimary, width: 4),
                                  right: BorderSide(color: AppColors.pinkPrimary, width: 4),
                                ),
                              ),
                            ),
                          ),
                          // Bottom-left corner
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: AppColors.pinkPrimary, width: 4),
                                  left: BorderSide(color: AppColors.pinkPrimary, width: 4),
                                ),
                              ),
                            ),
                          ),
                          // Bottom-right corner
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: AppColors.pinkPrimary, width: 4),
                                  right: BorderSide(color: AppColors.pinkPrimary, width: 4),
                                ),
                              ),
                            ),
                          ),
                          // Center text
                          const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.qr_code_scanner,
                                  size: 32,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '將 QR Code 對準框內',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 50,
                left: 20,
                right: 20,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.pinkPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    '取消',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((code) {
      if (code != null) {
        setState(() {
          _selectedInvitationCode = code.toUpperCase();
          _invitationCodeController.text = code.toUpperCase();
        });
        // Automatically submit the form after scanning
        if (_formKey.currentState?.validate() ?? false) {
          _formKey.currentState?.save();
          final draft = _GroupDraft(
            groupMode: _selectedGroupMode,
            groupId: _selectedGroupId,
            invitationCode: _selectedInvitationCode,
            groupName: _groupNameController.text.trim(),
            memberIds: _parseMemberIds(_membersController.text),
          );
          // Don't pop here - let the onSave callback handle it after API call completes
          widget.onSave(draft);
        }
      }
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    _formKey.currentState?.save();

    final groupName = _groupNameController.text.trim();
    final memberIds = _parseMemberIds(_membersController.text);

    final draft = _GroupDraft(
      groupMode: _selectedGroupMode,
      groupId: _selectedGroupId,
      invitationCode: _selectedInvitationCode,
      groupName: groupName,
      memberIds: memberIds,
    );

    await widget.onSave(draft);
    // Don't pop here - parent handles sheet closing
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
                _selectedGroupMode == '建立群組' ? '建立群組' : '加入群組',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _selectedGroupMode == '建立群組'
                    ? '建立一個新的群組並邀請成員'
                    : '加入現有群組並邀請成員',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.inkLight),
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
              if (_selectedGroupMode == '建立群組')
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
                )
              else
                Column(
                  children: [
                    TextFormField(
                      controller: _invitationCodeController,
                      decoration: const InputDecoration(
                        labelText: '邀請碼',
                        hintText: '輸入要加入的群組邀請碼',
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return '請輸入邀請碼';
                        }
                        if ((value ?? '').trim().length != 6) {
                          return '邀請碼必須是 6 個字元';
                        }
                        return null;
                      },
                      onSaved: (value) {
                    _selectedInvitationCode = (value ?? '').trim().toUpperCase();
                  },
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => _showQRScanner(context),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('掃描 QR Code'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.pinkPrimary,
                      ),
                    ),
                  ],
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
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.onTap,
  });

  final GroupSummary group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.pinkPrimary.withValues(alpha: 0.15),
          child: const Icon(Icons.group, color: AppColors.pinkPrimary),
        ),
        title: Text(group.groupName),
        subtitle: Row(
          children: [
            Text('邀請碼: ${group.invitationCode}'),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                // Copy invitation code to clipboard
                await Clipboard.setData(ClipboardData(text: group.invitationCode));
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('邀請碼已複製'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                }
              },
              child: const Icon(
                Icons.content_copy,
                size: 16,
                color: AppColors.pinkPrimary,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class _SettlementSheet extends StatefulWidget {
  const _SettlementSheet({
    required this.group,
    required this.currentUserId,
  });

  final GroupSummary group;
  final int currentUserId;

  @override
  State<_SettlementSheet> createState() => _SettlementSheetState();
}

class _SettlementSheetState extends State<_SettlementSheet> {
  final ApiConnect _api = ApiConnect();
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _settlements = [];

  @override
  void initState() {
    super.initState();
    _loadSettlements();
  }

  Future<void> _loadSettlements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _api.settleGroupExpenses(widget.group.groupId);
      if (!mounted) {
        return;
      }
      setState(() {
        _settlements = (result['settlements'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = _readableError(error));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _readableError(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return '資料讀取失敗，請稍後再試。';
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.group.groupName} 結算建議',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '根據目前的分帳紀錄，建議的結算方式如下：',
            style: const TextStyle(color: AppColors.inkLight),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Card(
              color: AppColors.pinkSoft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_errorMessage!),
              ),
            )
          else if (_settlements.isEmpty)
            Card(
              color: AppColors.green.withValues(alpha: 0.1),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.green),
                    SizedBox(width: 8),
                    Expanded(child: Text('所有帳款已結算完成！')),
                  ],
                ),
              ),
            )
          else
            ..._settlements.map(
              (settlement) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.pinkPrimary.withValues(alpha: 0.15),
                    child: const Icon(Icons.swap_horiz, color: AppColors.pinkPrimary),
                  ),
                  title: Text('${settlement['from_name']} → ${settlement['to_name']}'),
                  subtitle: Text('轉帳 \$${settlement['amount']}'),
                  trailing: Text(
                    '\$${settlement['amount']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.pinkPrimary,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: _loadSettlements,
              icon: const Icon(Icons.refresh),
              label: const Text('重新計算'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitEditorSheet extends StatefulWidget {
  const _SplitEditorSheet({
    required this.onSave,
    required this.availableGroups,
    required this.currentUserId,
  });

  final ValueChanged<_SplitDraft> onSave;
  final List<GroupSummary> availableGroups;
  final int currentUserId;

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
  int? _selectedGroupId;
  late bool _syncToLedger;
  late bool _sendConfirmation;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _subtitleController = TextEditingController();
    _amountController = TextEditingController();
    _membersController = TextEditingController(
      text: '${widget.currentUserId}, 2, 3',
    );
    _proportionsController = TextEditingController(
      text: '50, 25, 25',
    );
    _groupNameController = TextEditingController();
    _selectedStatus = '待付';
    _selectedIconName = '群組';
    _selectedGroupMode = '建立群組';
    _selectedGroupId = null;
    _syncToLedger = true;
    _sendConfirmation = true;
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
                '新增分帳',
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
              if (_selectedGroupMode == '建立群組')
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
                )
              else if (widget.availableGroups.isEmpty)
                Card(
                  color: AppColors.pinkSoft,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('目前沒有可加入的群組，請先建立群組。'),
                  ),
                )
              else
                DropdownButtonFormField<int>(
                  value: _selectedGroupId,
                  decoration: const InputDecoration(labelText: '選擇群組'),
                  items: widget.availableGroups
                      .map(
                        (group) => DropdownMenuItem<int>(
                          value: group.groupId,
                          child: Text('${group.groupName} (#${group.groupId})'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedGroupId = value),
                  validator: (value) {
                    if (_selectedGroupMode == '加入群組' && value == null) {
                      return '請選擇群組';
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
                  labelText: '成員 ID 清單',
                  hintText: '例如：1, 2, 3',
                ),
                maxLines: 2,
                maxLength: 80,
                validator: (value) {
                  if (_parseMemberIds(value).length < 2) {
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
                  final members = _parseMemberIds(_membersController.text);
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
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('平均分攤'),
                    onPressed: _setEqualSplit,
                  ),
                  ActionChip(
                    label: const Text('自訂'),
                    onPressed: () {
                      _proportionsController.clear();
                    },
                  ),
                ],
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

  void _setEqualSplit() {
    final members = _parseMemberIds(_membersController.text);
    if (members.isEmpty) {
      return;
    }
    final equalPercentage = (100 / members.length).toStringAsFixed(0);
    final equalProportions = List.filled(members.length, equalPercentage).join(', ');
    _proportionsController.text = equalProportions;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final subtitle = _subtitleController.text.trim();
    final amount = double.parse(
      _amountController.text.trim().replaceAll(',', ''),
    );
    final memberIds = _parseMemberIds(_membersController.text);
    final proportions = _splitPercentages(
      _proportionsController.text,
    ).map<double>((value) => value / 100).toList();

    final groupName = _selectedGroupMode == '建立群組'
        ? _groupNameController.text.trim()
        : _resolveSelectedGroupName();

    final draft = _SplitDraft(
      groupMode: _selectedGroupMode,
      groupId: _selectedGroupId,
      groupName: groupName,
      expenseName: subtitle,
      amount: amount,
      memberIds: memberIds,
      proportions: proportions,
      status: _selectedStatus,
      syncToLedger: _syncToLedger,
      sendConfirmation: _sendConfirmation,
    );

    final confirmed = await _confirmSplitSave(draft);
    if (!confirmed) {
      return;
    }

    if (!mounted) {
      return;
    }

    widget.onSave(draft);

    Navigator.pop(context);
  }

  String _resolveSelectedGroupName() {
    final group = widget.availableGroups
        .cast<GroupSummary?>()
        .firstWhere((item) => item?.groupId == _selectedGroupId, orElse: () => null);
    return group?.groupName ?? '未命名群組';
  }

  Future<bool> _confirmSplitSave(_SplitDraft draft) async {
    final memberSummary = draft.memberIds.isEmpty
        ? '未設定'
        : draft.memberIds.map((id) => id.toString()).join('、');
    final proportionSummary = draft.proportions.isEmpty
        ? '未設定比例'
        : draft.proportions
            .map((value) => '${(value * 100).toStringAsFixed(0)}%')
            .join(' / ');
    final amountLabel =
        '${draft.status} \$${_formatSplitAmount(draft.amount)}';

    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('確認分帳內容'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('群組：${draft.groupName}'),
                const SizedBox(height: 6),
                Text('成員：$memberSummary'),
                const SizedBox(height: 6),
                Text('比例：$proportionSummary'),
                const SizedBox(height: 6),
                Text('金額：$amountLabel'),
                const SizedBox(height: 6),
                Text('同步記帳：${draft.syncToLedger ? '是' : '否'}'),
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

  List<int> _parseMemberIds(String? value) {
    return (value ?? '')
        .split(',')
        .map((item) => int.tryParse(item.trim()) ?? -1)
        .where((item) => item > 0)
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

class _SplitDraft {
  const _SplitDraft({
    required this.groupMode,
    required this.groupName,
    required this.expenseName,
    required this.amount,
    required this.memberIds,
    required this.proportions,
    required this.status,
    required this.syncToLedger,
    required this.sendConfirmation,
    this.groupId,
  });

  final String groupMode;
  final String groupName;
  final String expenseName;
  final double amount;
  final List<int> memberIds;
  final List<double> proportions;
  final String status;
  final bool syncToLedger;
  final bool sendConfirmation;
  final int? groupId;
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



IconData _splitIconForName(String name) {
  return switch (name) {
    '旅行' => Icons.flight_takeoff,
    '採買' => Icons.shopping_cart,
    '咖啡' => Icons.local_cafe,
    _ => Icons.group,
  };
}
