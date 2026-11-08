import 'user.dart';
import 'task_share.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final DateTime? startDate;
  final DateTime? dueDate;
  final UserModel? createdBy;
  final List<UserModel> assignees;
  final UserModel? primaryAssignee;
  final List<TaskShareModel> shares;
  final String myRole;
  final String myPermission;
  final bool canEdit;
  final bool canDelete;
  final bool canManageAccess;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.startDate,
    this.dueDate,
    this.createdBy,
    this.assignees = const [],
    this.primaryAssignee,
    this.shares = const [],
    this.myRole = 'owner',
    this.myPermission = 'owner',
    this.canEdit = true,
    this.canDelete = true,
    this.canManageAccess = true,
    this.createdAt,
    this.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final rawCreator = json['createdBy'];
    final rawAssignees = json['assigneeIds'] as List<dynamic>? ?? [];
    final rawPrimary = json['primaryAssigneeId'];
    final rawShares = json['shares'] as List<dynamic>? ?? [];

    String rawStatus = (json['status'] ?? 'todo').toString();
    if (rawStatus == 'in-progress') rawStatus = 'in_progress';

    return TaskModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      status: rawStatus,
      priority: (json['priority'] ?? 'medium').toString(),
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'].toString())
          : null,
      createdBy: rawCreator is Map<String, dynamic>
          ? UserModel.fromJson(rawCreator)
          : null,
      assignees: rawAssignees
          .whereType<Map<String, dynamic>>()
          .map(UserModel.fromJson)
          .toList(),
      primaryAssignee: rawPrimary is Map<String, dynamic>
          ? UserModel.fromJson(rawPrimary)
          : null,
      shares: rawShares
          .whereType<Map<String, dynamic>>()
          .map(TaskShareModel.fromJson)
          .toList(),
      myRole: (json['myRole'] ?? 'owner').toString(),
      myPermission: (json['myPermission'] ?? 'owner').toString(),
      canEdit: json['canEdit'] != false,
      canDelete: json['canDelete'] == true,
      canManageAccess: json['canManageAccess'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}
