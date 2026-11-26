import 'package:flutter_test/flutter_test.dart';
import 'package:goaldigger_app/ui/auth/view_models/auth_view_model.dart';
import 'package:goaldigger_app/ui/session/session_view_model.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeAuthRepository repository;
  late SessionViewModel session;
  late AuthViewModel viewModel;

  setUp(() {
    repository = FakeAuthRepository();
    session = SessionViewModel();
    viewModel = AuthViewModel(authRepository: repository, session: session);
  });

  test('login rejects invalid input without calling the backend', () async {
    await viewModel.login(email: 'nope', password: '123');

    expect(viewModel.emailError, isNotNull);
    expect(viewModel.passwordError, isNotNull);
    expect(repository.loginCalls, 0);
    expect(session.isAuthenticated, isFalse);
  });

  test('successful login signs the session in with trimmed password', () async {
    await viewModel.login(email: 'a@b.co', password: ' secret ');

    expect(repository.lastPassword, 'secret');
    expect(session.user?.userId, 1);
    expect(viewModel.isSubmitting, isFalse);
    expect(viewModel.errorMessage, isNull);
  });

  test('backend failure surfaces its message', () async {
    repository.shouldFail = true;

    await viewModel.login(email: 'a@b.co', password: 'secret');

    expect(viewModel.errorMessage, '帳號或密碼錯誤');
    expect(session.isAuthenticated, isFalse);
  });

  test('register validates name and matching passwords', () async {
    viewModel.toggleMode();
    await viewModel.register(
      name: ' ',
      email: 'a@b.co',
      password: 'secret',
      confirmPassword: 'different',
    );

    expect(viewModel.nameError, isNotNull);
    expect(viewModel.confirmPasswordError, isNotNull);
    expect(session.isAuthenticated, isFalse);
  });

  test('toggling mode clears errors', () async {
    await viewModel.login(email: 'bad', password: '1');
    viewModel.toggleMode();

    expect(viewModel.mode, AuthMode.register);
    expect(viewModel.emailError, isNull);
    expect(viewModel.passwordError, isNull);
  });
}
