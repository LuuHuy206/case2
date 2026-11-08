import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../models/task_activity.dart';
import '../../services/task_service.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/status_badge.dart';
import '../assignment/assign_task_screen.dart';
import '../sharing/task_sharing_screen.dart';
import 'task_edit_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  TaskModel? _task;
  List<TaskActivityModel> _activities = [];
  List<Map<String, dynamic>> _emailLogs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final task = await TaskService.getTaskById(widget.taskId);
      final activities = await TaskService.getTaskActivities(widget.taskId);
      List<Map<String, dynamic>> logs = [];
      try {
        logs = await TaskService.getEmailLogs(widget.taskId);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _task = task;
        _activities = activities;
        _emailLogs = logs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _quickChangeStatus(String newStatus) async {
    try {
      await TaskService.updateStatus(widget.taskId, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật trạng thái công việc')),
      );
      _loadDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa công việc này? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await TaskService.deleteTask(widget.taskId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa công việc')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _retryEmail(String logId) async {
    try {
      await TaskService.retryEmailLog(logId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi lại email thông báo')),
      );
      _loadDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết công việc')),
        body: const LoadingView(),
      );
    }

    if (_error != null || _task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết công việc')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error ?? 'Không tìm thấy công việc'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _loadDetail,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final task = _task!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết công việc'),
        actions: [
          if (task.canEdit)
            IconButton(
              tooltip: 'Chỉnh sửa',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final updated = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => TaskEditScreen(task: task),
                  ),
                );
                if (updated == true) _loadDetail();
              },
            ),
          if (task.canDelete)
            IconButton(
              tooltip: 'Xóa công việc',
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDetail,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        StatusBadge(status: task.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        PriorityBadge(priority: task.priority),
                        Chip(
                          label: Text('Quyền của bạn: ${task.myPermission}'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      task.description.isEmpty
                          ? 'Không có mô tả chi tiết.'
                          : task.description,
                      style: const TextStyle(fontSize: 15, height: 1.4),
                    ),
                    const Divider(height: 28),
                    _infoRow(
                      Icons.person_outline,
                      'Người tạo',
                      task.createdBy != null
                          ? '${task.createdBy!.fullName} (${task.createdBy!.email})'
                          : 'Không rõ',
                    ),
                    const SizedBox(height: 8),
                    _infoRow(
                      Icons.play_circle_outline,
                      'Ngày bắt đầu',
                      DateFormatter.formatDate(task.startDate),
                    ),
                    const SizedBox(height: 8),
                    _infoRow(
                      Icons.event_outlined,
                      'Hạn hoàn thành',
                      DateFormatter.formatDate(task.dueDate),
                    ),
                    if (task.canEdit) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Cập nhật nhanh trạng thái:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: AppConstants.statuses.map((st) {
                          final selected = task.status == st;
                          return ChoiceChip(
                            label: Text(AppConstants.statusLabel(st)),
                            selected: selected,
                            onSelected: (val) {
                              if (val && !selected) _quickChangeStatus(st);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Assignees Section
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Người được giao việc',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (task.canManageAccess || task.canEdit)
                          TextButton.icon(
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AssignTaskScreen(task: task),
                                ),
                              );
                              _loadDetail();
                            },
                            icon: const Icon(Icons.group_add_outlined, size: 18),
                            label: const Text('Giao việc'),
                          ),
                      ],
                    ),
                    if (task.primaryAssignee != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Phụ trách chính: ${task.primaryAssignee!.fullName}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    if (task.assignees.isEmpty)
                      const Text(
                        'Chưa giao cho thành viên nào.',
                        style: TextStyle(color: Colors.black54),
                      )
                    else
                      ...task.assignees.map(
                        (u) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            child: Text(
                              u.fullName.isNotEmpty
                                  ? u.fullName[0].toUpperCase()
                                  : 'U',
                            ),
                          ),
                          title: Text(u.fullName),
                          subtitle: Text(u.email),
                          trailing: task.primaryAssignee?.id == u.id
                              ? const Chip(label: Text('Chính'))
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sharing Section
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Chia sẻ & Quyền truy cập',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (task.canManageAccess)
                          TextButton.icon(
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TaskSharingScreen(task: task),
                                ),
                              );
                              _loadDetail();
                            },
                            icon: const Icon(Icons.share_outlined, size: 18),
                            label: const Text('Quản lý chia sẻ'),
                          ),
                      ],
                    ),
                    if (task.shares.isEmpty)
                      const Text(
                        'Chưa chia sẻ công việc này cho ai.',
                        style: TextStyle(color: Colors.black54),
                      )
                    else
                      ...task.shares.map(
                        (sh) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.verified_user_outlined),
                          title: Text(sh.user?.fullName ?? 'Người dùng'),
                          subtitle: Text(sh.user?.email ?? ''),
                          trailing: Chip(
                            label: Text(
                              sh.permission == 'editor'
                                  ? 'Chỉnh sửa (Editor)'
                                  : 'Chỉ xem (Viewer)',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Email Logs Section
            if (_emailLogs.isNotEmpty) ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lịch sử gửi Email thông báo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._emailLogs.map((log) {
                        final status = (log['status'] ?? 'pending').toString();
                        final id = (log['_id'] ?? log['id'] ?? '').toString();
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            status == 'sent'
                                ? Icons.mark_email_read_outlined
                                : Icons.error_outline,
                            color:
                                status == 'sent' ? Colors.green : Colors.orange,
                          ),
                          title: Text(
                              '${log['recipientEmail']} — ${log['subject']}'),
                          subtitle: Text('Trạng thái: $status'),
                          trailing: status == 'failed'
                              ? TextButton(
                                  onPressed: () => _retryEmail(id),
                                  child: const Text('Gửi lại'),
                                )
                              : null,
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Activities Section
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lịch sử hoạt động',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_activities.isEmpty)
                      const Text(
                        'Chưa có hoạt động nào được ghi nhận.',
                        style: TextStyle(color: Colors.black54),
                      )
                    else
                      ..._activities.map(
                        (act) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.history, size: 20),
                          title: Text(
                            '${act.user?.fullName ?? "Hệ thống"} — ${act.action}',
                          ),
                          subtitle: Text(
                            DateFormatter.formatDateTime(act.createdAt),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.black54)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
