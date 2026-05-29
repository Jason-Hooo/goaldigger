part of '../main.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.onAuth});

  final ValueChanged<AuthUser> onAuth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const PinkBackground(),
          SafeArea(child: AuthPage(onAuth: onAuth)),
        ],
      ),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.onAuth});

  final ValueChanged<AuthUser> onAuth;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final ApiConnect _api = ApiConnect();
  
  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _registerNameController = TextEditingController();
  final TextEditingController _registerEmailController = TextEditingController();
  final TextEditingController _registerPasswordController = TextEditingController();
  final TextEditingController _registerConfirmPasswordController = TextEditingController();
  
  // State
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isLoginMode = true;
  
  // Validation state (紅字提示)
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 💡 移除邊打字邊檢查的 addListener，改為按下按鈕時才檢查
  }

  // --- 防呆驗證邏輯 ---
  bool _isValidEmail(String input) {
    final emailRegex = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+");
    return emailRegex.hasMatch(input);
  }

  bool _validateLoginFields() {
    bool isValid = true;
    setState(() {
      _emailError = _isValidEmail(_emailController.text) ? null : '請輸入有效的 Email';
      _passwordError = (_passwordController.text.length >= 6) ? null : '密碼至少 6 碼';
      if (_emailError != null || _passwordError != null) isValid = false;
    });
    return isValid;
  }

  bool _validateRegisterFields() {
    bool isValid = true;
    setState(() {
      _emailError = _isValidEmail(_registerEmailController.text) ? null : '請輸入有效的 Email';
      _passwordError = (_registerPasswordController.text.length >= 6) ? null : '密碼至少 6 碼';
      _confirmPasswordError = (_registerPasswordController.text == _registerConfirmPasswordController.text)
          ? null
          : '兩次輸入的密碼不相符';
      
      // 若有其他欄位檢查(如姓名不得為空)也可加在這
      if (_registerNameController.text.isEmpty) isValid = false;

      if (_emailError != null || _passwordError != null || _confirmPasswordError != null) {
        isValid = false;
      }
    });
    return isValid;
  }

  Future<void> _handleLogin() async {
    // 1. 先把上一次的「伺服器錯誤訊息」清空
    setState(() => _errorMessage = null);

    // 2. 執行防呆檢查，如果不通過就直接攔截！
    // 💡 輸入框自己會變紅，不跳出頂部的驚嘆號大卡片
    if (!_validateLoginFields()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = await _api.login(email: email, password: password);
      widget.onAuth(user);
    } catch (error) {
      setState(() => _errorMessage = _readableError(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleRegister() async {
    // 1. 先把上一次的「伺服器錯誤訊息」清空
    setState(() => _errorMessage = null);

    // 2. 執行防呆檢查，如果不通過就直接攔截！
    if (!_validateRegisterFields()) return;

    final name = _registerNameController.text.trim();
    final email = _registerEmailController.text.trim();
    final password = _registerPasswordController.text.trim();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = await _api.register(
        name: name,
        email: email,
        password: password,
      );
      widget.onAuth(user);
    } catch (error) {
      setState(() => _errorMessage = _readableError(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _readableError(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return '發生錯誤，請稍後再試。';
  }

  // --- UI 構建 ---
  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: _isLoginMode ? '登入' : '註冊',
      subtitle: _isLoginMode ? '使用 Email 登入或以 Google 繼續。' : '建立你的帳號。',
      child: Column(
        children: [
          const SizedBox(height: 12),
          
          // 頂部錯誤訊息卡片
          if (_errorMessage != null)
            Card(
              color: AppColors.pinkSoft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.pinkPrimary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_errorMessage!)),
                  ],
                ),
              ),
            ),
          if (_errorMessage != null) const SizedBox(height: 12),
          
          // 登入或註冊表單主體
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _isLoginMode ? _buildLoginForm(context) : _buildRegisterForm(context),
            ),
          ),
          
          const SizedBox(height: 24),

          // 1. 登入/註冊 切換列
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isLoginMode ? '尚未註冊？' : '已有帳號？',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        setState(() {
                          _isLoginMode = !_isLoginMode;
                          _errorMessage = null;
                          // 切換模式時清除所有防呆紅字
                          _emailError = null;
                          _passwordError = null;
                          _confirmPasswordError = null;
                        });
                      },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  _isLoginMode ? '立即註冊' : '點此登入',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Email 登入', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email_outlined),
            errorText: _emailError,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: '密碼',
            prefixIcon: const Icon(Icons.lock_outline),
            errorText: _passwordError,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            // 💡 按鈕隨時可按，點擊後才觸發 _handleLogin 去檢查防呆
            onPressed: _isSubmitting ? null : _handleLogin,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('登入'),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Email 註冊', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        TextField(
          controller: _registerNameController,
          decoration: InputDecoration(
            labelText: '姓名',
            prefixIcon: const Icon(Icons.person_outline),
            // 若你需要姓名防呆紅字，可在此加上 errorText
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _registerEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email_outlined),
            errorText: _emailError,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _registerPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: '密碼',
            prefixIcon: const Icon(Icons.lock_outline),
            errorText: _passwordError,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _registerConfirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: '再次輸入密碼',
            prefixIcon: const Icon(Icons.lock_outline),
            errorText: _confirmPasswordError,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _handleRegister,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('註冊'),
          ),
        ),
      ],
    );
  }
}