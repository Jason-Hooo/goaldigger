part of '../main.dart';

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
