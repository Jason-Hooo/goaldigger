part of '../main.dart';

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  late final List<Widget> _pages = [
    LedgerPage(user: widget.user),
    GoalsPage(user: widget.user),
    StatsPage(user: widget.user),
    SplitPage(user: widget.user),
    SettingsPage(onLogout: widget.onLogout, user: widget.user),
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
