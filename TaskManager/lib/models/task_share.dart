import 'user.dart';

class TaskShareModel {
  final String id;
  final String taskId;
  final UserModel? user;
  final String permission; // viewer | editor
  final DateTime? createdAt;

  TaskShareModel({
    required this.id,
    required this.taskId,
    this.user,
    required this.permission,
    this.createdAt,
  });

  factory TaskShareModel.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'] ?? json['userId'];
    return TaskShareModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      taskId: (json['taskId'] ?? '').toString(),
      user: rawUser is Map<String, dynamic> ? UserModel.fromJson(rawUser) : null,
      permission: (json['permission'] ?? 'viewer').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
