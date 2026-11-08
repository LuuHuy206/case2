import 'package:flutter/material.dart';
import '../../models/notification.dart';
import '../../services/notification_service.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/loading_view.dart';
import '../tasks/task_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<AppNotificationModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await NotificationService.getNotifications();
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    await NotificationService.markAllAsRead();
    _load();
  }

  Future<void> _openNotification(AppNotificationModel item) async {
    if (!item.isRead) {
      await NotificationService.markAsRead(item.id);
    }
    if (!mounted) return;
    if (item.taskId != null && item.taskId!.isNotEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TaskDetailScreen(taskId: item.taskId!),
        ),
      );
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (_items.any((n) => !n.isRead))
            TextButton.icon(
              onPressed: _markAllRead,
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Đọc tất cả'),
            ),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _items.isEmpty
              ? const Center(
                  child: Text(
                    'Bạn chưa có thông báo nào.',
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final n = _items[index];
                      return Card(
                        elevation: 0,
                        color: n.isRead
                            ? Colors.white
                            : const Color(0xFFEFF6FF),
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          onTap: () => _openNotification(n),
                          leading: CircleAvatar(
                            backgroundColor: n.isRead
                                ? Colors.grey.shade200
                                : const Color(0xFFDBEAFE),
                            child: Icon(
                              Icons.notifications_active_outlined,
                              color: n.isRead
                                  ? Colors.black54
                                  : const Color(0xFF2563EB),
                            ),
                          ),
                          title: Text(
                            n.title,
                            style: TextStyle(
                              fontWeight: n.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(n.message),
                              const SizedBox(height: 4),
                              Text(
                                DateFormatter.formatDateTime(n.createdAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
