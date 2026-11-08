class AppNotificationModel {
  final String id;
  final String? taskId;
  final String? taskTitle;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  AppNotificationModel({
    required this.id,
    this.taskId,
    this.taskTitle,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    this.createdAt,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    final rawTask = json['taskId'];
    String? extractedTaskId;
    String? extractedTitle;
    if (rawTask is Map<String, dynamic>) {
      extractedTaskId = (rawTask['_id'] ?? rawTask['id'])?.toString();
      extractedTitle = rawTask['title']?.toString();
    } else if (rawTask != null) {
      extractedTaskId = rawTask.toString();
    }

    return AppNotificationModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      taskId: extractedTaskId,
      taskTitle: extractedTitle,
      type: (json['type'] ?? 'task_updated').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      isRead: json['isRead'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
