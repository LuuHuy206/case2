import '../models/task_share.dart';
import 'api_client.dart';

class TaskShareService {
  static Future<List<TaskShareModel>> getShares(String taskId) async {
    final res = await ApiClient.get('/tasks/\$taskId/shares');
    final list = res['shares'] as List<dynamic>? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(TaskShareModel.fromJson)
        .toList();
  }

  static Future<void> shareTask(
    String taskId, {
    List<String> userIds = const [],
    List<String> emails = const [],
    required String permission,
  }) async {
    await ApiClient.post('/tasks/\$taskId/shares', {
      'userIds': userIds,
      'emails': emails,
      'permission': permission,
    });
  }

  static Future<void> updatePermission(
    String taskId,
    String shareId,
    String permission,
  ) async {
    await ApiClient.patch('/tasks/\$taskId/shares/\$shareId', {
      'permission': permission,
    });
  }

  static Future<void> revokeShare(String taskId, String shareId) async {
    await ApiClient.delete('/tasks/\$taskId/shares/\$shareId');
  }
}
