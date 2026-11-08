import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../models/task_share.dart';
import '../../models/user.dart';
import '../../services/task_share_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/user_selector.dart';

class TaskSharingScreen extends StatefulWidget {
  final TaskModel task;

  const TaskSharingScreen({super.key, required this.task});

  @override
  State<TaskSharingScreen> createState() => _TaskSharingScreenState();
}

class _TaskSharingScreenState extends State<TaskSharingScreen> {
  List<TaskShareModel> _shares = [];
  List<UserModel> _selectedUsers = [];
  String _permission = 'viewer'; // viewer | editor
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadShares();
  }

  Future<void> _loadShares() async {
    setState(() => _loading = true);
    try {
      final list = await TaskShareService.getShares(widget.task.id);
      if (!mounted) return;
      setState(() {
        _shares = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _addShare() async {
    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng chọn ít nhất một người để chia sẻ')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await TaskShareService.shareTask(
        widget.task.id,
        userIds: _selectedUsers.map((u) => u.id).toList(),
        permission: _permission,
      );
      if (!mounted) return;
      setState(() => _selectedUsers = []);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã chia sẻ công việc và gửi email mời')),
      );
      _loadShares();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _changePermission(TaskShareModel share, String newPerm) async {
    try {
      await TaskShareService.updatePermission(
        widget.task.id,
        share.id,
        newPerm,
      );
      _loadShares();
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

  Future<void> _revoke(TaskShareModel share) async {
    try {
      await TaskShareService.revokeShare(widget.task.id, share.id);
      _loadShares();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thu hồi quyền chia sẻ')),
      );
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
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý chia sẻ & Quyền truy cập')),
      body: _loading
          ? const LoadingView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Công việc: ${widget.task.title}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Thêm người được chia sẻ:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  UserSelector(
                    initialSelected: _selectedUsers,
                    onChanged: (list) => setState(() => _selectedUsers = list),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _permission,
                    decoration: const InputDecoration(
                      labelText: 'Quyền truy cập cấp phát',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'viewer',
                        child: Text('Chỉ xem (Viewer)'),
                      ),
                      DropdownMenuItem(
                        value: 'editor',
                        child: Text('Chỉnh sửa (Editor)'),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _permission = v ?? 'viewer'),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _addShare,
                    icon: const Icon(Icons.share_outlined),
                    label: Text(
                      _submitting ? 'Đang chia sẻ...' : 'Cấp quyền chia sẻ',
                    ),
                  ),
                  const Divider(height: 36),
                  const Text(
                    'Danh sách người đang được chia sẻ:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_shares.isEmpty)
                    const Text(
                      'Chưa có người dùng nào được chia sẻ.',
                      style: TextStyle(color: Colors.black54),
                    )
                  else
                    ..._shares.map(
                      (sh) => Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          title: Text(sh.user?.fullName ?? 'Người dùng'),
                          subtitle: Text(sh.user?.email ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButton<String>(
                                value: sh.permission,
                                underline: const SizedBox.shrink(),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'viewer',
                                    child: Text('Viewer'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'editor',
                                    child: Text('Editor'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null && val != sh.permission) {
                                    _changePermission(sh, val);
                                  }
                                },
                              ),
                              IconButton(
                                tooltip: 'Thu hồi quyền',
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => _revoke(sh),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
