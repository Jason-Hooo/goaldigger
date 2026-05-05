import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const GoalDiggerApp());
}

class GoalDiggerApp extends StatelessWidget {
  const GoalDiggerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.pinkPrimary,
        primary: AppColors.pinkPrimary,
        secondary: AppColors.pinkSecondary,
        surface: AppColors.surfaceSoft,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GoalDigger',
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: AppColors.surfaceSoft,
        textTheme: GoogleFonts.baloo2TextTheme(baseTheme.textTheme).copyWith(
          headlineLarge: GoogleFonts.baloo2(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          titleLarge: GoogleFonts.baloo2(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.pinkPrimary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            textStyle: GoogleFonts.baloo2(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isAuthed = false;

  void _handleAuth() {
    setState(() => _isAuthed = true);
  }

  void _handleLogout() {
    setState(() => _isAuthed = false);
  }

  @override
  Widget build(BuildContext context) {
    return _isAuthed
      ? HomeShell(onLogout: _handleLogout)
      : AuthShell(onAuth: _handleAuth);
  }
}

class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.onAuth});

  final VoidCallback onAuth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const PinkBackground(),
          SafeArea(
            child: AuthPage(onAuth: onAuth),
          ),
        ],
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  late final List<Widget> _pages = [
    const LedgerPage(),
    const GoalsPage(),
    const StatsPage(),
    const SplitPage(),
    SettingsPage(onLogout: widget.onLogout),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const PinkBackground(),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: _pages[_index],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 14,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (value) => setState(() => _index = value),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.pinkPrimary,
          unselectedItemColor: AppColors.inkLight,
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: '記帳',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.flag_rounded),
              label: '目標',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              label: '報表',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_rounded),
              label: '分帳',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: '設定',
            ),
          ],
        ),
      ),
    );
  }
}

class PinkBackground extends StatelessWidget {
  const PinkBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFE7F0), Color(0xFFFFF6FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: const [
          Positioned(
            top: -40,
            left: -20,
            child: DecorBlob(size: 140, color: Color(0xFFFFC7DA)),
          ),
          Positioned(
            top: 180,
            right: -60,
            child: DecorBlob(size: 200, color: Color(0xFFFFD9E8)),
          ),
          Positioned(
            bottom: -40,
            left: 30,
            child: DecorBlob(size: 160, color: Color(0xFFFFC0D6)),
          ),
        ],
      ),
    );
  }
}

class DecorBlob extends StatelessWidget {
  const DecorBlob({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.6),
      ),
    );
  }
}

class AuthPage extends StatelessWidget {
  const AuthPage({super.key, required this.onAuth});

  final VoidCallback onAuth;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: '登入',
      subtitle: '使用 Email 或 Google 登入。',
      child: Column(
        children: [
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email 登入',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: '密碼',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onAuth,
                      child: const Text('使用 Email 登入'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '快速登入',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onAuth,
                      icon: const Icon(Icons.g_mobiledata_rounded),
                      label: const Text('使用 Google 登入'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LedgerPage extends StatelessWidget {
  const LedgerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: '記帳',
      subtitle: '收入與支出快速整理。',
      child: Column(
        children: [
          const SizedBox(height: 12),
          _BalanceCard(balance: 2480.25, income: 3200.0, expense: 719.75),
          const SizedBox(height: 20),
          _SectionHeader(title: '最新紀錄'),
          const SizedBox(height: 12),
          ...ledgerItems.map((item) => LedgerTile(item: item)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('新增紀錄'),
          ),
        ],
      ),
    );
  }
}

class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: '目標',
      subtitle: '用可愛存錢罐存下夢想。',
      child: Column(
        children: [
          const SizedBox(height: 12),
          ...goalItems.map((item) => GoalTile(item: item)),
          const SizedBox(height: 20),
          _SectionHeader(title: '下一步'),
          const SizedBox(height: 12),
          _ChecklistCard(
            items: const [
              '設定自動存錢',
              '新增里程碑獎勵',
              '邀請夥伴',
            ],
          ),
        ],
      ),
    );
  }
}

class SplitPage extends StatelessWidget {
  const SplitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: '分帳',
      subtitle: '團體帳單與共享目標。',
      child: Column(
        children: [
          const SizedBox(height: 12),
          _MiniRow(
            items: const [
              _Pill(label: '京都旅行'),
              _Pill(label: '室友'),
              _Pill(label: '咖啡好友'),
            ],
          ),
          const SizedBox(height: 16),
          ...splitItems.map((item) => SplitTile(item: item)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.group_add_rounded),
            label: const Text('建立群組'),
          ),
        ],
      ),
    );
  }
}

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: '報表',
      subtitle: '簡單圖表與洞察。',
      child: Column(
        children: [
          const SizedBox(height: 12),
          _ChartCard(
            title: '支出比例',
            data: const [
              _ChartSlice(label: '餐飲', value: 0.35),
              _ChartSlice(label: '旅行', value: 0.25),
              _ChartSlice(label: '購物', value: 0.18),
              _ChartSlice(label: '帳單', value: 0.22),
            ],
          ),
          const SizedBox(height: 16),
          _ChartCard(
            title: '目標進度',
            data: const [
              _ChartSlice(label: '相機', value: 0.6),
              _ChartSlice(label: '健身', value: 0.42),
              _ChartSlice(label: '旅行', value: 0.8),
            ],
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: '設定',
      subtitle: '管理帳號與偏好設定。',
      child: Column(
        children: [
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('帳號', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      CircleAvatar(
                        backgroundColor: AppColors.pinkSoft,
                        child: Icon(
                          Icons.person_rounded,
                          color: AppColors.pinkPrimary,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Piggy',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout),
                    label: const Text('登出'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageScaffold extends StatelessWidget {
  const _PageScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Text(title, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.inkLight),
          ),
          const SizedBox(height: 18),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 12 * (1 - value)),
                child: child,
              ),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.savings_rounded, color: AppColors.pinkPrimary),
                SizedBox(width: 8),
                Text('小豬閃亮模式'),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.inkLight),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onPressed, child: Text(actionText)),
          ],
        ),
      ),
    );
  }
}

class _MiniRow extends StatelessWidget {
  const _MiniRow({required this.items});

  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 10, runSpacing: 10, children: items);
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.pinkSoft),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        Text(
              '示範',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: AppColors.pinkPrimary),
        ),
      ],
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.pinkPrimary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(item)),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.income,
    required this.expense,
  });

  final double balance;
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '本月結餘',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '\$${balance.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatChip(
                  label: '收入',
                  value: income,
                  color: AppColors.green,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  label: '支出',
                  value: expense,
                  color: AppColors.pinkPrimary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('\$${value.toStringAsFixed(0)}'),
          ],
        ),
      ),
    );
  }
}

class LedgerTile extends StatelessWidget {
  const LedgerTile({super.key, required this.item});

  final LedgerItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.pinkSoft,
          child: Icon(item.icon, color: AppColors.pinkPrimary),
        ),
        title: Text(item.title),
        subtitle: Text(item.subtitle),
        trailing: Text(
          item.amount,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: item.isIncome ? AppColors.green : AppColors.pinkPrimary,
          ),
        ),
      ),
    );
  }
}

class GoalTile extends StatelessWidget {
  const GoalTile({super.key, required this.item});

  final GoalItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.title, style: Theme.of(context).textTheme.titleLarge),
                Text('${(item.progress * 100).toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: item.progress,
                minHeight: 10,
                backgroundColor: AppColors.pinkSoft,
                valueColor: const AlwaysStoppedAnimation(AppColors.pinkPrimary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.subtitle,
              style: const TextStyle(color: AppColors.inkLight),
            ),
          ],
        ),
      ),
    );
  }
}

class SplitTile extends StatelessWidget {
  const SplitTile({super.key, required this.item});

  final SplitItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.pinkSoft,
          child: Icon(item.icon, color: AppColors.pinkPrimary),
        ),
        title: Text(item.title),
        subtitle: Text(item.subtitle),
        trailing: Text(
          item.amount,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.data});

  final String title;
  final List<_ChartSlice> data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Column(
              children: data
                  .map(
                    (slice) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: slice.value,
                                minHeight: 10,
                                backgroundColor: AppColors.pinkSoft,
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.pinkPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 86,
                            child: Text(
                              '${slice.label} ${(slice.value * 100).toStringAsFixed(0)}%',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

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

class GoalItem {
  GoalItem({
    required this.title,
    required this.subtitle,
    required this.progress,
  });

  final String title;
  final String subtitle;
  final double progress;
}

class SplitItem {
  SplitItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String amount;
  final IconData icon;
}

class _ChartSlice {
  const _ChartSlice({required this.label, required this.value});

  final String label;
  final double value;
}

class AppColors {
  static const pinkPrimary = Color(0xFFF05A91);
  static const pinkSecondary = Color(0xFFFF9EBB);
  static const pinkSoft = Color(0xFFFFD3E3);
  static const surfaceSoft = Color(0xFFFFF6FA);
  static const ink = Color(0xFF3B2E32);
  static const inkLight = Color(0xFF8B6E79);
  static const green = Color(0xFF2FA678);
}

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
