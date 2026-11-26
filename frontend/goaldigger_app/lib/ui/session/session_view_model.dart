import '../../data/models/auth_user.dart';
import '../core/view_models/view_model.dart';

/// App-wide authentication state. Drives the [AuthGate].
class SessionViewModel extends ViewModel {
  AuthUser? _user;

  AuthUser? get user => _user;

  bool get isAuthenticated => _user != null;

  void signIn(AuthUser user) {
    _user = user;
    notifyListeners();
  }

  void signOut() {
    _user = null;
    notifyListeners();
  }
}
