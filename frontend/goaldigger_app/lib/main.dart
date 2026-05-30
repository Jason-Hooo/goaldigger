import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:async';

part 'theme/app_colors.dart';
part 'models/ledger_item.dart';
part 'models/goal_item.dart';
part 'models/split_item.dart';
part 'models/demo_data.dart';
part 'viewmodels/auth_gate_viewmodel.dart';
part 'viewmodels/home_shell_viewmodel.dart';
part 'views/app_view.dart';
part 'views/auth_view.dart';
part 'views/home_shell_view.dart';
part 'views/ledger_view.dart';
part 'views/goals_view.dart';
part 'views/stats_view.dart';
part 'views/split_view.dart';
part 'widgets/background_widgets.dart';
part 'widgets/page_scaffold.dart';
part 'widgets/misc_widgets.dart';
part 'services/app_refresh_bus.dart';
part 'services/realtime_refresh.dart';
part 'api/api_connect.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: _loadSupabaseUrl(),
    anonKey: _loadSupabaseAnonKey(),
  );
  runApp(const GoalDiggerApp());
}

String _loadSupabaseUrl() {
  final rawUrl = dotenv.env['SUPABASE_URL']?.trim();
  if (rawUrl == null || rawUrl.isEmpty) {
    throw StateError('Missing SUPABASE_URL in .env');
  }

  return rawUrl.replaceFirst(RegExp(r'/rest/v1/?$'), '');
}

String _loadSupabaseAnonKey() {
  final anonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim();
  if (anonKey == null || anonKey.isEmpty) {
    throw StateError('Missing SUPABASE_ANON_KEY in .env');
  }

  return anonKey;
}
