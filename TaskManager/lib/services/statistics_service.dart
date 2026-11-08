import 'api_client.dart';

class StatisticsService {
  static Future<Map<String, dynamic>> getTaskStats() async {
    final res = await ApiClient.get('/statistics/tasks');
    return (res['statistics'] as Map<String, dynamic>?) ?? {};
  }

  static Future<Map<String, dynamic>> getAssignmentStats() async {
    final res = await ApiClient.get('/statistics/assignments');
    return (res['statistics'] as Map<String, dynamic>?) ?? {};
  }

  static Future<Map<String, dynamic>> getDeadlineStats() async {
    final res = await ApiClient.get('/statistics/deadlines');
    return (res['statistics'] as Map<String, dynamic>?) ?? {};
  }
}
