import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../models/user.dart';
import '../../services/task_service.dart';
import '../../widgets/user_selector.dart';

class AssignTaskScreen extends StatefulWidget {
  final TaskModel task;

  const AssignTaskScreen({super.key, required this.task});

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  late List<UserModel> _selectedUsers;
  String? _primaryAssigneeId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedUsers = List<UserModel>.from(widget.task.assignees);
    _primaryAssigneeId = widget.task.primaryAssignee?.id;
  }

  Future<void> _saveAssignment() async {
    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất một người phụ trách'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final ids = _selectedUsers.map((u) => u.id).toList();
      final primaryId = (_primaryAssigneeId != null &&
              ids.contains(_primaryAssigneeId))
          ? _primaryAssigneeId
          : ids.first;

      await TaskService.assignTask(
        widget.task.id,
        userIds: ids,
        primaryAssigneeId: primaryId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã giao công việc và gửi thông báo thành công!'),
        ),
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
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removeAssignee(UserModel user) async {
    try {
      await TaskService.removeAssignee(widget.task.id, user.id);
      setState(() {
        _selectedUsers.removeWhere((u) => u.id == user.id);
        if (_primaryAssigneeId == user.id) {
          _primaryAssigneeId =
              _selectedUsers.isNotEmpty ? _selectedUsers.first.id : null;
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã hủy giao việc cho ${user.fullName}')),
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
      appBar: AppBar(title: const Text('Giao công việc')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Công việc: ${widget.task.title}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              '1. Tìm và chọn thành viên thực hiện:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            UserSelector(
              initialSelected: _selectedUsers,
              onChanged: (list) {
                setState(() {
                  _selectedUsers = list;
                  if (_primaryAssigneeId == null && list.isNotEmpty) {
                    _primaryAssigneeId = list.first.id;
                  } else if (_primaryAssigneeId != null &&
                      !list.any((u) => u.id == _primaryAssigneeId)) {
                    _primaryAssigneeId = list.isNotEmpty ? list.first.id : null;
                  }
                });
              },
            ),
            const SizedBox(height: 20),
            if (_selectedUsers.isNotEmpty) ...[
              const Text(
                '2. Chỉ định người phụ trách chính:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ..._selectedUsers.map(
                (u) => RadioListTile<String>(
                  value: u.id,
                  groupValue: _primaryAssigneeId,
                  title: Text(u.fullName),
                  subtitle: Text(u.email),
                  secondary: IconButton(
                    tooltip: 'Hủy giao việc',
                    icon: const Icon(Icons.person_remove_outlined,
                        color: Colors.redAccent),
                    onPressed: () => _removeAssignee(u),
                  ),
                  onChanged: (val) => setState(() => _primaryAssigneeId = val),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _saveAssignment,
              icon: const Icon(Icons.send_outlined),
              label: Text(
                _saving
                    ? 'Đang xử lý...'
                    : 'Xác nhận giao việc & Gửi Email thông báo',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
