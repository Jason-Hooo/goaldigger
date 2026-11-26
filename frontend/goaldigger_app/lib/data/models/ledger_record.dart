/// A personal income / expense record.
class LedgerRecord {
  const LedgerRecord({
    required this.recordId,
    required this.typeId,
    required this.amount,
    required this.createdAt,
    this.description,
    this.typeName,
    this.isExpense,
    this.goalId,
    this.groupConsumptionId,
  });

  factory LedgerRecord.fromJson(Map<String, dynamic> json) {
    return LedgerRecord(
      recordId: json['consumption_id'] as int,
      typeId: json['type_id'] as int,
      amount: (json['amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      description: json['description'] as String?,
      typeName: json['type_name'] as String?,
      isExpense: json['is_expense'] as bool?,
      goalId: json['goal_id'] as int?,
      groupConsumptionId: json['group_consumption_id'] as int?,
    );
  }

  final int recordId;
  final int typeId;
  final double amount;
  final DateTime createdAt;
  final String? description;
  final String? typeName;
  final bool? isExpense;
  final int? goalId;
  final int? groupConsumptionId;

  /// The backend stores the title and note in a single `description` column,
  /// joined by [descriptionSeparator].
  static const String descriptionSeparator = ' · ';

  static String encodeDescription({
    required String title,
    required String note,
  }) {
    return note.isEmpty ? title : '$title$descriptionSeparator$note';
  }

  List<String> get _descriptionParts =>
      (description ?? '').trim().split(descriptionSeparator);

  /// The title part of [description], or [fallback] when absent.
  String titleOr(String fallback) {
    return _descriptionParts.firstWhere(
      (part) => part.isNotEmpty,
      orElse: () => fallback,
    );
  }

  /// The note part of [description] (everything after the first separator).
  String get note {
    final parts = _descriptionParts;
    return parts.length > 1 ? parts.sublist(1).join(descriptionSeparator) : '';
  }
}
