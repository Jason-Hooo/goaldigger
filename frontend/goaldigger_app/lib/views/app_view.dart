part of '../main.dart';

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
