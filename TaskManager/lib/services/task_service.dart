import '../models/task.dart';
import '../models/task_activity.dart';
import 'api_client.dart';

class TaskService {
  static Future<List<TaskModel>> getTasks({
    String scope = 'all',
    String? status,
    String? priority,
    String? assigneeId,
    String? query,
    String sortBy = 'createdAt',
    String order = 'desc',
  }) async {
    final params = <String, String>{
      'scope': scope,
      'sortBy': sortBy,
      'order': order,
    };
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (priority != null && priority.isNotEmpty) params['priority'] = priority;
    if (assigneeId != null && assigneeId.isNotEmpty) params['assigneeId'] = assigneeId;
    if (query != null && query.trim().isNotEmpty) params['q'] = query.trim();

    final res = await ApiClient.get('/tasks', queryParams: params);
    final list = res['tasks'] as List<dynamic>? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(TaskModel.fromJson)
        .toList();
  }

  static Future<TaskModel> getTaskById(String id) async {
    final res = await ApiClient.get('/tasks/\$id');
    return TaskModel.fromJson(res['task'] as Map<String, dynamic>);
  }

  static Future<TaskModel> createTask({
    required String title,
    String description = '',
    String status = 'todo',
    String priority = 'medium',
    DateTime? startDate,
    DateTime? dueDate,
  }) async {
    final res = await ApiClient.post('/tasks', {
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'startDate': startDate?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
    });
    return TaskModel.fromJson(res['task'] as Map<String, dynamic>);
  }

  static Future<TaskModel> updateTask(
    String id, {
    String? title,
    String? description,
    String? status,
    String? priority,
    DateTime? startDate,
    DateTime? dueDate,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (status != null) body['status'] = status;
    if (priority != null) body['priority'] = priority;
    if (startDate != null) body['startDate'] = startDate.toIso8601String();
    if (dueDate != null) body['dueDate'] = dueDate.toIso8601String();

    final res = await ApiClient.put('/tasks/\$id', body);
    return TaskModel.fromJson(res['task'] as Map<String, dynamic>);
  }

  static Future<TaskModel> updateStatus(String id, String status) async {
    final res = await ApiClient.patch('/tasks/\$id/status', {'status': status});
    return TaskModel.fromJson(res['task'] as Map<String, dynamic>);
  }

  static Future<void> deleteTask(String id) async {
    await ApiClient.delete('/tasks/\$id');
  }

  static Future<List<TaskActivityModel>> getTaskActivities(String taskId) async {
    final res = await ApiClient.get('/tasks/\$taskId/activities');
    final list = res['activities'] as List<dynamic>? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(TaskActivityModel.fromJson)
        .toList();
  }

  static Future<void> assignTask(
    String taskId, {
    required List<String> userIds,
    String? primaryAssigneeId,
  }) async {
    await ApiClient.post('/tasks/\$taskId/assignees', {
      'userIds': userIds,
      if (primaryAssigneeId != null) 'primaryAssigneeId': primaryAssigneeId,
    });
  }

  static Future<void> setPrimaryAssignee(String taskId, String userId) async {
    await ApiClient.patch('/tasks/\$taskId/assignees/\$userId', {
      'isPrimary': true,
    });
  }

  static Future<void> removeAssignee(String taskId, String userId) async {
    await ApiClient.delete('/tasks/\$taskId/assignees/\$userId');
  }

  static Future<List<Map<String, dynamic>>> getEmailLogs(String taskId) async {
    final res = await ApiClient.get('/tasks/\$taskId/email-logs');
    final list = res['emailLogs'] as List<dynamic>? ?? [];
    return list.whereType<Map<String, dynamic>>().toList();
  }

  static Future<void> retryEmailLog(String emailLogId) async {
    await ApiClient.post('/email-logs/\$emailLogId/retry', {});
  }
}
