import '../models/notification.dart';
import 'api_client.dart';

class NotificationService {
  static Future<List<AppNotificationModel>> getNotifications() async {
    final res = await ApiClient.get('/notifications');
    final list = res['notifications'] as List<dynamic>? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(AppNotificationModel.fromJson)
        .toList();
  }

  static Future<int> getUnreadCount() async {
    final res = await ApiClient.get('/notifications/unread-count');
    return (res['unreadCount'] as num?)?.toInt() ?? 0;
  }

  static Future<void> markAsRead(String id) async {
    await ApiClient.patch('/notifications/\$id/read', {});
  }

  static Future<void> markAllAsRead() async {
    await ApiClient.patch('/notifications/read-all', {});
  }
}
