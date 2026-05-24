part of '../main.dart';

class LedgerItem {
  LedgerItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isIncome,
    required this.icon,
    this.recordedAt,
  });

  final String title;
  final String subtitle;
  final String amount;
  final bool isIncome;
  final IconData icon;
  final DateTime? recordedAt;

  String get recordedAtLabel {
    final recordedAt = this.recordedAt;
    if (recordedAt == null) {
      return '未標記時間';
    }
    return '${recordedAt.year}/${recordedAt.month}/${recordedAt.day}';
  }
}
