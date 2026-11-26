/// A ledger category. Predefined categories have no owner; custom ones belong
/// to a single user.
class ExpenseType {
  const ExpenseType({
    required this.id,
    required this.name,
    required this.isExpense,
    this.ownerUserId,
  });

  factory ExpenseType.fromJson(Map<String, dynamic> json) {
    return ExpenseType(
      id: json['type_id'] as int,
      name: json['type_name'] as String? ?? '未分類',
      isExpense: json['is_expense'] as bool? ?? true,
      ownerUserId: json['user_id'] as int?,
    );
  }

  final int id;
  final String name;
  final bool isExpense;
  final int? ownerUserId;

  bool get isCustom => ownerUserId != null;

  ExpenseType copyWith({int? id, String? name, bool? isExpense}) {
    return ExpenseType(
      id: id ?? this.id,
      name: name ?? this.name,
      isExpense: isExpense ?? this.isExpense,
      ownerUserId: ownerUserId,
    );
  }
}

/// User input for creating or editing a custom [ExpenseType].
class ExpenseTypeDraft {
  const ExpenseTypeDraft({required this.name, required this.isExpense});

  final String name;
  final bool isExpense;
}
