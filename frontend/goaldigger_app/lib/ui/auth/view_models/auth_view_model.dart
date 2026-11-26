import '../../../core/errors/app_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/auth_user.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../core/view_models/view_model.dart';
import '../../session/session_view_model.dart';

enum AuthMode { login, register }

class AuthViewModel extends ViewModel {
  AuthViewModel({
    required AuthRepository authRepository,
    required SessionViewModel session,
  }) : _authRepository = authRepository,
       _session = session;

  static const int minPasswordLength = 6;
  static const String _fallbackError = '發生錯誤，請稍後再試。';

  final AuthRepository _authRepository;
  final SessionViewModel _session;

  AuthMode _mode = AuthMode.login;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  AuthMode get mode => _mode;
  bool get isLoginMode => _mode == AuthMode.login;
  bool get isSubmitting => _isSubmitting;

  /// Server-side failure shown above the form.
  String? get errorMessage => _errorMessage;
  String? get nameError => _nameError;
  String? get emailError => _emailError;
  String? get passwordError => _passwordError;
  String? get confirmPasswordError => _confirmPasswordError;

  void toggleMode() {
    if (_isSubmitting) {
      return;
    }
    _mode = isLoginMode ? AuthMode.register : AuthMode.login;
    _clearErrors();
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    _errorMessage = null;
    _nameError = null;
    _confirmPasswordError = null;
    _emailError = _validateEmail(email);
    _passwordError = _validatePassword(password);
    if (_emailError != null || _passwordError != null) {
      notifyListeners();
      return;
    }

    await _submit(
      () => _authRepository.login(
        email: email.trim(),
        password: password.trim(),
      ),
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    _errorMessage = null;
    _nameError = name.trim().isEmpty ? '請輸入姓名' : null;
    _emailError = _validateEmail(email);
    _passwordError = _validatePassword(password);
    _confirmPasswordError = password == confirmPassword ? null : '兩次輸入的密碼不相符';
    if (_nameError != null ||
        _emailError != null ||
        _passwordError != null ||
        _confirmPasswordError != null) {
      notifyListeners();
      return;
    }

    await _submit(
      () => _authRepository.register(
        name: name.trim(),
        email: email.trim(),
        password: password.trim(),
      ),
    );
  }

  Future<void> _submit(Future<AuthUser> Function() request) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      final user = await request();
      _session.signIn(user);
    } catch (error) {
      _errorMessage = describeError(error, fallback: _fallbackError);
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  String? _validateEmail(String email) =>
      Validators.isValidEmail(email) ? null : '請輸入有效的 Email';

  String? _validatePassword(String password) =>
      password.length >= minPasswordLength ? null : '密碼至少 $minPasswordLength 碼';

  void _clearErrors() {
    _errorMessage = null;
    _nameError = null;
    _emailError = null;
    _passwordError = null;
    _confirmPasswordError = null;
  }
}
