part of '../main.dart';

final List<LedgerItem> ledgerItems = [
  LedgerItem(
    title: '早晨拿鐵',
    subtitle: '咖啡店 - 餐飲',
    amount: '-\$4.50',
    isIncome: false,
    icon: Icons.local_cafe,
  ),
  LedgerItem(
    title: '薪資入帳',
    subtitle: '每月收入',
    amount: '+\$3,200',
    isIncome: true,
    icon: Icons.payments,
  ),
  LedgerItem(
    title: '小豬貼紙',
    subtitle: '購物',
    amount: '-\$18.90',
    isIncome: false,
    icon: Icons.shopping_bag,
  ),
];

final List<GoalItem> goalItems = [
  GoalItem(
    title: '相機基金',
    subtitle: '8 月前存到 \$1,200',
    progress: 0.6,
  ),
  GoalItem(
    title: '週末小旅行',
    subtitle: '10 月前存到 \$800',
    progress: 0.42,
  ),
  GoalItem(
    title: '緊急預備金',
    subtitle: '12 月前存到 \$2,000',
    progress: 0.2,
  ),
];

final List<SplitItem> splitItems = [
  SplitItem(
    title: '京都旅行',
    subtitle: '3 位朋友 - 晚餐與計程車',
    amount: '待付 \$46',
    icon: Icons.flight_takeoff,
  ),
  SplitItem(
    title: '室友採買',
    subtitle: '2 人 - 每週採購',
    amount: '待收 \$23',
    icon: Icons.shopping_cart,
  ),
  SplitItem(
    title: '咖啡好友',
    subtitle: '4 人 - 每月聚會',
    amount: '待付 \$12',
    icon: Icons.group,
  ),
];
