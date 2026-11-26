import '../../../core/utils/formatters.dart';

/// Presentation model for a single ledger row.
class LedgerEntry {
  const LedgerEntry({
    required this.recordId,
    required this.typeId,
    required this.title,
    required this.note,
    required this.categoryName,
    required this.amount,
    required this.isIncome,
    this.goalId,
    this.recordedAt,
  });

  final int recordId;
  final int typeId;
  final int? goalId;
  final String title;
  final String note;
  final String categoryName;
  final double amount;
  final bool isIncome;
  final DateTime? recordedAt;

  String get subtitle => note.isEmpty ? categoryName : '$categoryName · $note';

  String get amountLabel =>
      '${isIncome ? '+' : '-'}\$${Formatters.amount(amount)}';

  String get typeLabel => isIncome ? '收入' : '支出';

  String get recordedAtLabel {
    final recordedAt = this.recordedAt;
    return recordedAt == null ? '未標記時間' : Formatters.shortDate(recordedAt);
  }
}

/// Form output of the ledger entry sheet.
class LedgerDraft {
  const LedgerDraft({
    this.recordId,
    required this.title,
    required this.note,
    required this.amount,
    required this.isIncome,
    required this.typeId,
    this.goalId,
  });

  /// `null` when creating a new record.
  final int? recordId;
  final String title;
  final String note;
  final double amount;
  final bool isIncome;
  final int typeId;
  final int? goalId;

  bool get isNew => recordId == null;
}
