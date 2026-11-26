import '../../models/stats.dart';

abstract interface class StatsRepository {
  Future<List<CategoryStat>> fetchCategoryStats(int userId);

  Future<List<TrendPoint>> fetchTrend(int userId, {int days = 30});
}
