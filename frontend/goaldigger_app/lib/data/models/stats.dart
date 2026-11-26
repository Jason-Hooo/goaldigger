/// Aggregated amount per category, as computed by the backend.
class CategoryStat {
  const CategoryStat({required this.category, required this.amount});

  factory CategoryStat.fromJson(Map<String, dynamic> json) {
    return CategoryStat(
      category: json['category'] as String? ?? '未分類',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }

  final String category;
  final double amount;
}

/// Daily spending total.
class TrendPoint {
  const TrendPoint({required this.date, required this.totalAmount});

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      date: DateTime.parse(json['date'] as String),
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
    );
  }

  final DateTime date;
  final double totalAmount;
}
