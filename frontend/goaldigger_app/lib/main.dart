import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
//apiConnect.dart
import 'package:shared_preferences/shared_preferences.dart';


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
part 'api/api_connect.dart';

void main() {
  runApp(const GoalDiggerApp());
}
