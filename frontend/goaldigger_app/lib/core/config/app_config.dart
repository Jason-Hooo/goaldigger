import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Strongly-typed runtime configuration loaded from the bundled `.env` file.
///
/// All environment access goes through this class so that missing keys fail
/// fast at startup instead of surfacing later as obscure network errors.
class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.apiBaseUrl,
  });

  /// Reads `.env` from the asset bundle and builds an [AppConfig].
  static Future<AppConfig> load({String fileName = '.env'}) async {
    await dotenv.load(fileName: fileName);
    return AppConfig.fromEnvironment(dotenv.env);
  }

  factory AppConfig.fromEnvironment(Map<String, String> env) {
    return AppConfig(
      supabaseUrl: _require(env, 'SUPABASE_URL')
          .replaceFirst(RegExp(r'/rest/v1/?$'), ''),
      supabaseAnonKey: _require(env, 'SUPABASE_ANON_KEY'),
      apiBaseUrl: _require(env, 'API_BASE_URL').replaceFirst(RegExp(r'/$'), ''),
    );
  }

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String apiBaseUrl;

  static String _require(Map<String, String> env, String key) {
    final value = env[key]?.trim();
    if (value == null || value.isEmpty) {
      throw StateError('Missing $key in .env');
    }
    return value;
  }
}
