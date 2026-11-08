import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/statistics_service.dart';
import '../../widgets/loading_view.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  Map<String, dynamic> _taskStats = {};
  Map<String, dynamic> _assignmentStats = {};
  Map<String, dynamic> _deadlineStats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        AuthService.getCurrentUser(),
        StatisticsService.getTaskStats(),
        StatisticsService.getAssignmentStats(),
        StatisticsService.getDeadlineStats(),
      ]);
      if (!mounted) return;
      setState(() {
        _user = results[0] as UserModel;
        _taskStats = results[1] as Map<String, dynamic>;
        _assignmentStats = results[2] as Map<String, dynamic>;
        _deadlineStats = results[3] as Map<String, dynamic>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _showEditProfileDialog() async {
    if (_user == null) return;
    final nameCtrl = TextEditingController(text: _user!.fullName);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cập nhật hồ sơ'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Họ và tên',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              await AuthService.updateProfile(fullName: nameCtrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (saved == true) _loadAll();
  }

  Future<void> _showChangePasswordDialog() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu hiện tại',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu mới (>= 8 ký tự)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await AuthService.changePassword(
                  currentPassword: currentCtrl.text,
                  newPassword: newCtrl.text,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đổi mật khẩu thành công!')),
                );
              } catch (e) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(e.toString().replaceFirst('Exception: ', '')),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              }
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cá nhân & Thống kê')),
      body: _loading
          ? const LoadingView()
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_user != null)
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: const Color(0xFFDBEAFE),
                              child: Text(
                                _user!.fullName.isNotEmpty
                                    ? _user!.fullName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _user!.fullName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _user!.email,
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _showEditProfileDialog,
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  label: const Text('Sửa hồ sơ'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _showChangePasswordDialog,
                                  icon: const Icon(Icons.lock_reset_outlined,
                                      size: 18),
                                  label: const Text('Đổi mật khẩu'),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: _logout,
                                  icon: const Icon(Icons.logout, size: 18),
                                  label: const Text('Đăng xuất'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Thống kê công việc theo trạng thái',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _statCard(
                        'Tổng số',
                        '${_taskStats['total'] ?? 0}',
                        Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _statCard(
                        'Chưa làm',
                        '${_taskStats['todo'] ?? 0}',
                        Colors.blueGrey,
                      ),
                      const SizedBox(width: 8),
                      _statCard(
                        'Đang làm',
                        '${_taskStats['inProgress'] ?? _taskStats['in_progress'] ?? 0}',
                        Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      _statCard(
                        'Hoàn thành',
                        '${_taskStats['completed'] ?? 0}',
                        Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Thống kê giao việc & phụ trách',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _statCard(
                        'Đã tạo',
                        '${_assignmentStats['createdCount'] ?? 0}',
                        Colors.indigo,
                      ),
                      const SizedBox(width: 8),
                      _statCard(
                        'Được giao',
                        '${_assignmentStats['assignedCount'] ?? 0}',
                        Colors.teal,
                      ),
                      const SizedBox(width: 8),
                      _statCard(
                        'Phụ trách chính',
                        '${_assignmentStats['primaryAssigneeCount'] ?? 0}',
                        Colors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Thống kê hạn hoàn thành',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _statCard(
                        'Sắp đến hạn (48h)',
                        '${_deadlineStats['dueSoonCount'] ?? 0}',
                        Colors.amber.shade800,
                      ),
                      const SizedBox(width: 8),
                      _statCard(
                        'Đã quá hạn',
                        '${_deadlineStats['overdueCount'] ?? 0}',
                        Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
