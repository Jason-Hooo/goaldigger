part of '../main.dart';

class LedgerItem {
  LedgerItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isIncome,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String amount;
  final bool isIncome;
  final IconData icon;
}
