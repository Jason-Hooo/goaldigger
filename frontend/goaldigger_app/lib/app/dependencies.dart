import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';
import '../data/repositories/auth/auth_repository.dart';
import '../data/repositories/auth/auth_repository_remote.dart';
import '../data/repositories/expense_type/expense_type_repository.dart';
import '../data/repositories/expense_type/expense_type_repository_remote.dart';
import '../data/repositories/goal/goal_repository.dart';
import '../data/repositories/goal/goal_repository_remote.dart';
import '../data/repositories/ledger/ledger_repository.dart';
import '../data/repositories/ledger/ledger_repository_remote.dart';
import '../data/repositories/split/split_repository.dart';
import '../data/repositories/split/split_repository_remote.dart';
import '../data/repositories/stats/stats_repository.dart';
import '../data/repositories/stats/stats_repository_remote.dart';
import '../data/services/api/api_client.dart';
import '../data/services/data_change_notifier.dart';
import '../data/services/realtime/realtime_service.dart';
import '../ui/session/session_view_model.dart';

/// Composition root: wires services, repositories and app-scoped view models.
///
/// Repositories are exposed by their abstract type so that view models never
/// depend on a concrete data source.
List<SingleChildWidget> buildDependencies({
  required AppConfig config,
  required SupabaseClient supabase,
}) {
  return [
    // Services
    Provider<ApiClient>(
      create: (_) => ApiClient(baseUrl: config.apiBaseUrl),
      dispose: (_, client) => client.close(),
    ),
    Provider<RealtimeService>(create: (_) => SupabaseRealtimeService(supabase)),
    ChangeNotifierProvider<DataChangeNotifier>(
      create: (_) => DataChangeNotifier(),
    ),

    // Repositories
    Provider<AuthRepository>(
      create: (context) => AuthRepositoryRemote(context.read()),
    ),
    Provider<ExpenseTypeRepository>(
      create: (context) =>
          ExpenseTypeRepositoryRemote(context.read(), context.read()),
    ),
    Provider<LedgerRepository>(
      create: (context) =>
          LedgerRepositoryRemote(context.read(), context.read()),
    ),
    Provider<GoalRepository>(
      create: (context) => GoalRepositoryRemote(context.read(), context.read()),
    ),
    Provider<StatsRepository>(
      create: (context) => StatsRepositoryRemote(context.read()),
    ),
    Provider<SplitRepository>(
      create: (context) =>
          SplitRepositoryRemote(context.read(), context.read()),
    ),

    // App-scoped state
    ChangeNotifierProvider<SessionViewModel>(
      create: (_) => SessionViewModel(),
    ),
  ];
}
