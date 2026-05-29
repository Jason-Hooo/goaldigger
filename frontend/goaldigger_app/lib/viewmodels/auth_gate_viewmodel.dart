part of '../main.dart';

class _AuthGateState extends State<AuthGate> {
  bool _isAuthed = false;
  AuthUser? _user;

  void _handleAuth(AuthUser user) {
    setState(() {
      _isAuthed = true;
      _user = user;
    });
  }

  void _handleLogout() {
    setState(() {
      _isAuthed = false;
      _user = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isAuthed && _user != null
        ? HomeShell(onLogout: _handleLogout, user: _user!)
        : AuthShell(onAuth: _handleAuth);
  }
}
