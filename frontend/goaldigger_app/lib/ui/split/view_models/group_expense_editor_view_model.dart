import 'dart:async';

import '../../../core/errors/app_exception.dart';
import '../../../core/result/result.dart';
import '../../../data/models/expense_type.dart';
import '../../../data/models/split.dart';
import '../../../data/repositories/expense_type/expense_type_repository.dart';
import '../../../data/repositories/split/split_repository.dart';
import '../../core/view_models/view_model.dart';

/// State for creating or editing a group expense and its per-member split.
class GroupExpenseEditorViewModel extends ViewModel {
  GroupExpenseEditorViewModel({
    required this.userId,
    required this.group,
    required SplitRepository splitRepository,
    required ExpenseTypeRepository expenseTypeRepository,
    this.initialExpense,
  }) : _splitRepository = splitRepository,
       _expenseTypeRepository = expenseTypeRepository;

  /// Shares may differ from the total by at most this much (rounding).
  static const double tolerance = 0.5;

  final int userId;
  final GroupSummary group;
  final SplitExpense? initialExpense;
  final SplitRepository _splitRepository;
  final ExpenseTypeRepository _expenseTypeRepository;

  bool _isLoadingMembers = true;
  String? _membersError;
  List<GroupMember> _members = const [];
  List<ExpenseType> _expenseTypes = const [];
  int? _selectedTypeId;
  String? _validationError;
  bool _isSaving = false;

  bool get isEditing => initialExpense != null;
  bool get isLoadingMembers => _isLoadingMembers;
  String? get membersError => _membersError;
  List<GroupMember> get members => _members;

  /// Predefined (non-custom) expense categories.
  List<ExpenseType> get expenseTypes => _expenseTypes;
  int? get selectedTypeId => _selectedTypeId;
  String? get validationError => _validationError;
  bool get isSaving => _isSaving;

  void init() {
    unawaited(_loadMembers());
    unawaited(_loadExpenseTypes());
  }

  /// The share an existing participant had, used to prefill the form.
  double? initialShareFor(int userId) =>
      initialExpense?.participantFor(userId)?.sharedAmount;

  /// Equal share per member for [total], or `null` if it cannot be computed.
  double? equalShare(double? total) {
    if (total == null || total <= 0 || _members.isEmpty) {
      return null;
    }
    return total / _members.length;
  }

  void selectType(int? typeId) {
    _selectedTypeId = typeId;
    _validationError = null;
    notifyListeners();
  }

  void clearValidationError() {
    if (_validationError != null) {
      _validationError = null;
      notifyListeners();
    }
  }

  /// Validates and persists the expense. On success returns the submitted
  /// request so the caller can render it optimistically.
  Future<Result<SplitExpenseRequest>> submit({
    required String name,
    required double amount,
    required Map<int, double> shares,
  }) async {
    final totalShares = _members.fold<double>(
      0,
      (sum, member) => sum + (shares[member.userId] ?? 0),
    );
    if ((totalShares - amount).abs() > tolerance) {
      _validationError = '成員分攤金額總和必須等於總金額';
      notifyListeners();
      return Result.failure(_validationError!);
    }

    final request = SplitExpenseRequest(
      consumptionId: initialExpense?.consumptionId,
      groupId: group.groupId,
      name: name,
      amount: amount,
      payerId: userId,
      typeId: _selectedTypeId,
      shares: [
        for (final member in _members)
          SplitShare(
            userId: member.userId,
            sharedAmount: shares[member.userId] ?? 0,
          ),
      ],
    );

    _isSaving = true;
    _validationError = null;
    notifyListeners();

    final result = await guard(() async {
      await _splitRepository.saveExpense(request);
      return request;
    });
    _isSaving = false;
    if (result case Failure(:final message)) {
      _validationError = message;
    }
    notifyListeners();
    return result;
  }

  Future<void> _loadMembers() async {
    _isLoadingMembers = true;
    _membersError = null;
    notifyListeners();
    try {
      _members = await _splitRepository.fetchGroupMembers(group.groupId);
    } catch (error) {
      _membersError = describeError(error);
    } finally {
      _isLoadingMembers = false;
      notifyListeners();
    }
  }

  Future<void> _loadExpenseTypes() async {
    try {
      final types = await _expenseTypeRepository.fetchAll();
      _expenseTypes = types
          .where((type) => !type.isCustom && type.isExpense)
          .toList();
      notifyListeners();
    } catch (_) {
      // Categories are optional for a split expense; ignore failures.
    }
  }
}
