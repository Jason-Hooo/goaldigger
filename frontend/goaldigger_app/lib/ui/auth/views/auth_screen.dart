import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/page_scaffold.dart';
import '../../core/widgets/pink_background.dart';
import '../view_models/auth_view_model.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BackgroundScaffold(body: _AuthForm());
  }
}

class _AuthForm extends StatefulWidget {
  const _AuthForm();

  @override
  State<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<_AuthForm> {
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _registerName = TextEditingController();
  final _registerEmail = TextEditingController();
  final _registerPassword = TextEditingController();
  final _registerConfirmPassword = TextEditingController();

  @override
  void dispose() {
    for (final controller in [
      _loginEmail,
      _loginPassword,
      _registerName,
      _registerEmail,
      _registerPassword,
      _registerConfirmPassword,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit(AuthViewModel viewModel) {
    if (viewModel.isLoginMode) {
      viewModel.login(email: _loginEmail.text, password: _loginPassword.text);
    } else {
      viewModel.register(
        name: _registerName.text,
        email: _registerEmail.text,
        password: _registerPassword.text,
        confirmPassword: _registerConfirmPassword.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AuthViewModel>();
    final isLogin = viewModel.isLoginMode;
    final errorMessage = viewModel.errorMessage;

    return PageScaffold(
      title: isLogin ? '登入' : '註冊',
      subtitle: isLogin ? '使用 Email 登入或以 Google 繼續。' : '建立你的帳號。',
      child: Column(
        children: [
          const SizedBox(height: 12),
          if (errorMessage != null) ...[
            Card(
              color: AppColors.pinkSoft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.pinkPrimary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(errorMessage)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: isLogin
                  ? _buildLoginFields(viewModel)
                  : _buildRegisterFields(viewModel),
            ),
          ),
          const SizedBox(height: 24),
          _ModeSwitcher(viewModel: viewModel),
        ],
      ),
    );
  }

  Widget _buildLoginFields(AuthViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Email 登入', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _AuthTextField(
          controller: _loginEmail,
          label: 'Email',
          icon: Icons.email_outlined,
          errorText: viewModel.emailError,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _AuthTextField(
          controller: _loginPassword,
          label: '密碼',
          icon: Icons.lock_outline,
          errorText: viewModel.passwordError,
          obscureText: true,
        ),
        const SizedBox(height: 16),
        _SubmitButton(
          label: '登入',
          isBusy: viewModel.isSubmitting,
          onPressed: () => _submit(viewModel),
        ),
      ],
    );
  }

  Widget _buildRegisterFields(AuthViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Email 註冊', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _AuthTextField(
          controller: _registerName,
          label: '姓名',
          icon: Icons.person_outline,
          errorText: viewModel.nameError,
        ),
        const SizedBox(height: 12),
        _AuthTextField(
          controller: _registerEmail,
          label: 'Email',
          icon: Icons.email_outlined,
          errorText: viewModel.emailError,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _AuthTextField(
          controller: _registerPassword,
          label: '密碼',
          icon: Icons.lock_outline,
          errorText: viewModel.passwordError,
          obscureText: true,
        ),
        const SizedBox(height: 12),
        _AuthTextField(
          controller: _registerConfirmPassword,
          label: '再次輸入密碼',
          icon: Icons.lock_outline,
          errorText: viewModel.confirmPasswordError,
          obscureText: true,
        ),
        const SizedBox(height: 16),
        _SubmitButton(
          label: '註冊',
          isBusy: viewModel.isSubmitting,
          onPressed: () => _submit(viewModel),
        ),
      ],
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.errorText,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? errorText;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        errorText: errorText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.isBusy,
    required this.onPressed,
  });

  final String label;
  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isBusy ? null : onPressed,
        child: isBusy ? const ButtonSpinner() : Text(label),
      ),
    );
  }
}

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({required this.viewModel});

  final AuthViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final isLogin = viewModel.isLoginMode;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isLogin ? '尚未註冊？' : '已有帳號？',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        TextButton(
          onPressed: viewModel.isSubmitting ? null : viewModel.toggleMode,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            isLogin ? '立即註冊' : '點此登入',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ],
    );
  }
}
