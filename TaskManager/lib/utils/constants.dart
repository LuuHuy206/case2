import 'package:flutter/foundation.dart';

class AppConstants {
  static String get apiBaseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl;
    if (kIsWeb) return 'http://localhost:3000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  static const List<String> statuses = ['todo', 'in_progress', 'completed'];
  static const List<String> priorities = ['low', 'medium', 'high'];

  static String statusLabel(String status) {
    switch (status) {
      case 'in_progress':
      case 'in-progress':
        return 'Đang thực hiện';
      case 'completed':
        return 'Đã hoàn thành';
      case 'todo':
      default:
        return 'Chưa thực hiện';
    }
  }

  static String priorityLabel(String priority) {
    switch (priority) {
      case 'high':
        return 'Cao';
      case 'low':
        return 'Thấp';
      case 'medium':
      default:
        return 'Trung bình';
    }
  }
}
