import '../../models/stats.dart';
import '../../services/api/api_client.dart';
import 'stats_repository.dart';

class StatsRepositoryRemote implements StatsRepository {
  StatsRepositoryRemote(this._api);

  final ApiClient _api;

  @override
  Future<List<CategoryStat>> fetchCategoryStats(int userId) async {
    final body = await _api.get('/stats/category/$userId');
    return body.asJsonList.map(CategoryStat.fromJson).toList();
  }

  @override
  Future<List<TrendPoint>> fetchTrend(int userId, {int days = 30}) async {
    final body = await _api.get(
      '/stats/trend/$userId',
      query: {'days': '$days'},
    );
    return body.asJsonList.map(TrendPoint.fromJson).toList();
  }
}
