import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/auth_user.dart';
import '../../core/widgets/pink_background.dart';
import '../../goals/view_models/goals_view_model.dart';
import '../../goals/views/goals_screen.dart';
import '../../ledger/view_models/ledger_view_model.dart';
import '../../ledger/views/ledger_screen.dart';
import '../../settings/view_models/settings_view_model.dart';
import '../../settings/views/settings_screen.dart';
import '../../split/view_models/split_view_model.dart';
import '../../split/views/split_screen.dart';
import '../../stats/view_models/stats_view_model.dart';
import '../../stats/views/stats_screen.dart';

/// Authenticated shell with bottom navigation.
///
/// Owns the per-user feature view models; they live as long as the session so
/// tab switches keep state (the tabs are kept alive by an [IndexedStack]).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.user});

  final AuthUser user;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _destinations = [
    BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: '記帳'),
    BottomNavigationBarItem(icon: Icon(Icons.flag_rounded), label: '目標'),
    BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: '報表'),
    BottomNavigationBarItem(icon: Icon(Icons.group_rounded), label: '分帳'),
    BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: '設定'),
  ];

  @override
  Widget build(BuildContext context) {
    final userId = widget.user.userId;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => LedgerViewModel(
            userId: userId,
            ledgerRepository: context.read(),
            expenseTypeRepository: context.read(),
            goalRepository: context.read(),
            dataChanges: context.read(),
            realtime: context.read(),
          )..init(),
        ),
        ChangeNotifierProvider(
          create: (context) => GoalsViewModel(
            userId: userId,
            goalRepository: context.read(),
            dataChanges: context.read(),
          )..init(),
        ),
        ChangeNotifierProvider(
          create: (context) => StatsViewModel(
            userId: userId,
            ledgerRepository: context.read(),
            expenseTypeRepository: context.read(),
            statsRepository: context.read(),
            dataChanges: context.read(),
            realtime: context.read(),
          )..init(),
        ),
        ChangeNotifierProvider(
          create: (context) => SplitViewModel(
            userId: userId,
            splitRepository: context.read(),
            dataChanges: context.read(),
          )..init(),
        ),
        ChangeNotifierProvider(
          create: (context) => SettingsViewModel(
            userId: userId,
            expenseTypeRepository: context.read(),
          )..init(),
        ),
      ],
      child: BackgroundScaffold(
        body: IndexedStack(
          index: _index,
          children: [
            const LedgerScreen(),
            const GoalsScreen(),
            const StatsScreen(),
            const SplitScreen(),
            SettingsScreen(user: widget.user),
          ],
        ),
        bottomNavigationBar: _BottomBar(
          currentIndex: _index,
          onTap: (index) => setState(() => _index = index),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
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
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.pinkPrimary,
        unselectedItemColor: AppColors.inkLight,
        backgroundColor: Colors.transparent,
        elevation: 0,
        items: _HomeShellState._destinations,
      ),
    );
  }
}
