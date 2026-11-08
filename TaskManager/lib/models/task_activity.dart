import 'user.dart';

class TaskActivityModel {
  final String id;
  final String taskId;
  final UserModel? user;
  final String action;
  final Map<String, dynamic> details;
  final DateTime? createdAt;

  TaskActivityModel({
    required this.id,
    required this.taskId,
    this.user,
    required this.action,
    this.details = const {},
    this.createdAt,
  });

  factory TaskActivityModel.fromJson(Map<String, dynamic> json) {
    final rawUser = json['userId'];
    return TaskActivityModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      taskId: (json['taskId'] ?? '').toString(),
      user: rawUser is Map<String, dynamic> ? UserModel.fromJson(rawUser) : null,
      action: (json['action'] ?? '').toString(),
      details: json['details'] is Map<String, dynamic>
          ? json['details'] as Map<String, dynamic>
          : {},
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
