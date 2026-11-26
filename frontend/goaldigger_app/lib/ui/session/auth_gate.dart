import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/view_models/auth_view_model.dart';
import '../auth/views/auth_screen.dart';
import '../home/views/home_shell.dart';
import 'session_view_model.dart';

/// Shows the authenticated shell or the auth flow based on session state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionViewModel>().user;
    if (user != null) {
      // Keyed by user so all feature view models are rebuilt per account.
      return HomeShell(key: ValueKey(user.userId), user: user);
    }
    return ChangeNotifierProvider(
      create: (context) => AuthViewModel(
        authRepository: context.read(),
        session: context.read(),
      ),
      child: const AuthScreen(),
    );
  }
}
