import '../../models/auth_user.dart';

abstract interface class AuthRepository {
  Future<AuthUser> login({required String email, required String password});

  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  });

  Future<void> deleteAccount({required int userId, required String password});
}
