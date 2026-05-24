part of '../main.dart';

final List<LedgerItem> ledgerItems = [
  LedgerItem(
    title: '早晨拿鐵',
    subtitle: '咖啡店 - 餐飲',
    amount: '-\$4.50',
    isIncome: false,
    icon: Icons.local_cafe,
    recordedAt: DateTime(2026, 5, 22),
  ),
  LedgerItem(
    title: '薪資入帳',
    subtitle: '每月收入',
    amount: '+\$3,200',
    isIncome: true,
    icon: Icons.payments,
    recordedAt: DateTime(2026, 5, 20),
  ),
  LedgerItem(
    title: '小豬貼紙',
    subtitle: '購物',
    amount: '-\$18.90',
    isIncome: false,
    icon: Icons.shopping_bag,
    recordedAt: DateTime(2026, 5, 18),
  ),
];

final List<GoalItem> goalItems = [
  GoalItem(
    title: '相機基金',
    description: '想買 Sony 相機和一顆標準變焦鏡。',
    targetAmount: 1200,
    deadline: DateTime(2026, 8, 31),
    savedAmount: 720,
  ),
  GoalItem(
    title: '週末小旅行',
    description: '安排一次兩天一夜的小旅行。',
    targetAmount: 800,
    deadline: DateTime(2026, 10, 15),
    savedAmount: 336,
  ),
  GoalItem(
    title: '緊急預備金',
    description: '至少先存到三個月生活費。',
    targetAmount: 2000,
    deadline: DateTime(2026, 12, 31),
    savedAmount: 400,
  ),
  GoalItem(
    title: '筆電升級',
    description: '已完成的舊筆電升級計畫。',
    targetAmount: 1500,
    deadline: DateTime(2026, 4, 10),
    savedAmount: 1500,
    achievedAt: DateTime(2026, 4, 8),
  ),
];

final List<SplitItem> splitItems = [
  SplitItem(
    title: '京都旅行',
    subtitle: '3 位朋友 - 晚餐與計程車',
    amount: '待付 \$46',
    icon: Icons.flight_takeoff,
    groupMode: '建立群組',
    members: ['我', '小安', '阿哲'],
    proportions: [0.4, 0.3, 0.3],
    syncedToLedger: true,
    confirmationSent: true,
  ),
  SplitItem(
    title: '室友採買',
    subtitle: '2 人 - 每週採購',
    amount: '待收 \$23',
    icon: Icons.shopping_cart,
    groupMode: '加入群組',
    members: ['我', '室友'],
    proportions: [0.5, 0.5],
    syncedToLedger: false,
    confirmationSent: true,
  ),
  SplitItem(
    title: '咖啡好友',
    subtitle: '4 人 - 每月聚會',
    amount: '待付 \$12',
    icon: Icons.group,
    groupMode: '建立群組',
    members: ['我', '小美', '小明', '阿宏'],
    proportions: [0.25, 0.25, 0.25, 0.25],
    syncedToLedger: true,
    confirmationSent: false,
  ),
];
