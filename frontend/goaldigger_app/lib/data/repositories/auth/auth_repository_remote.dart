import '../../models/auth_user.dart';
import '../../services/api/api_client.dart';
import 'auth_repository.dart';

class AuthRepositoryRemote implements AuthRepository {
  AuthRepositoryRemote(this._api);

  final ApiClient _api;

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final body = await _api.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    return AuthUser.fromJson(body.dataEnvelope('登入失敗，無法取得使用者資料'));
  }

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final body = await _api.post(
      '/auth/register',
      body: {'name': name, 'email': email, 'password': password},
    );
    return AuthUser.fromJson(body.dataEnvelope('註冊失敗，無法取得使用者資料'));
  }

  @override
  Future<void> deleteAccount({
    required int userId,
    required String password,
  }) async {
    await _api.delete(
      '/auth/delete',
      body: {'user_id': userId, 'password': password},
    );
  }
}
