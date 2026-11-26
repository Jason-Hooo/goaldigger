import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../ui/session/auth_gate.dart';

class GoalDiggerApp extends StatelessWidget {
  const GoalDiggerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GoalDigger',
      theme: AppTheme.light(),
      home: const AuthGate(),
    );
  }
}
