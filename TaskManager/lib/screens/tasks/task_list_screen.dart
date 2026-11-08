import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/notification_service.dart';
import '../../services/task_service.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/task_card.dart';
import '../notifications/notification_screen.dart';
import '../profile/profile_screen.dart';
import 'task_create_screen.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();

  List<TaskModel> _tasks = [];
  bool _loading = true;
  String? _error;
  int _unreadCount = 0;

  String _scope = 'all'; // all | created | assigned | shared
  String? _statusFilter;
  String? _priorityFilter;
  String _sortBy = 'createdAt'; // createdAt | dueDate | priority
  String _order = 'desc';

  final List<Map<String, String>> _scopes = const [
    {'value': 'all', 'label': 'Tất cả'},
    {'value': 'created', 'label': 'Của tôi'},
    {'value': 'assigned', 'label': 'Được giao'},
    {'value': 'shared', 'label': 'Được chia sẻ'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _scopes.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _scope = _scopes[_tabController.index]['value']!;
        });
        _loadData();
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        TaskService.getTasks(
          scope: _scope,
          status: _statusFilter,
          priority: _priorityFilter,
          query: _searchCtrl.text,
          sortBy: _sortBy,
          order: _order,
        ),
        NotificationService.getUnreadCount(),
      ]);
      if (!mounted) return;
      setState(() {
        _tasks = results[0] as List<TaskModel>;
        _unreadCount = results[1] as int;
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

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String? tempStatus = _statusFilter;
        String? tempPriority = _priorityFilter;
        String tempSortBy = _sortBy;
        String tempOrder = _order;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Lọc & Sắp xếp công việc',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    value: tempStatus,
                    decoration: const InputDecoration(
                      labelText: 'Trạng thái',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tất cả')),
                      ...AppConstants.statuses.map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(AppConstants.statusLabel(s)),
                        ),
                      ),
                    ],
                    onChanged: (v) => setSheetState(() => tempStatus = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: tempPriority,
                    decoration: const InputDecoration(
                      labelText: 'Mức độ ưu tiên',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tất cả')),
                      ...AppConstants.priorities.map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(AppConstants.priorityLabel(p)),
                        ),
                      ),
                    ],
                    onChanged: (v) => setSheetState(() => tempPriority = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: tempSortBy,
                          decoration: const InputDecoration(
                            labelText: 'Sắp xếp theo',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'createdAt',
                              child: Text('Thời gian tạo'),
                            ),
                            DropdownMenuItem(
                              value: 'dueDate',
                              child: Text('Hạn hoàn thành'),
                            ),
                            DropdownMenuItem(
                              value: 'priority',
                              child: Text('Mức độ ưu tiên'),
                            ),
                          ],
                          onChanged: (v) =>
                              setSheetState(() => tempSortBy = v ?? 'createdAt'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: tempOrder,
                          decoration: const InputDecoration(
                            labelText: 'Thứ tự',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'desc', child: Text('Giảm dần')),
                            DropdownMenuItem(
                                value: 'asc', child: Text('Tăng dần')),
                          ],
                          onChanged: (v) =>
                              setSheetState(() => tempOrder = v ?? 'desc'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _statusFilter = null;
                              _priorityFilter = null;
                              _sortBy = 'createdAt';
                              _order = 'desc';
                            });
                            Navigator.pop(ctx);
                            _loadData();
                          },
                          child: const Text('Đặt lại'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _statusFilter = tempStatus;
                              _priorityFilter = tempPriority;
                              _sortBy = tempSortBy;
                              _order = tempOrder;
                            });
                            Navigator.pop(ctx);
                            _loadData();
                          },
                          child: const Text('Áp dụng'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản lý công việc',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Thông báo',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
              _loadData();
            },
            icon: Badge(
              isLabelVisible: _unreadCount > 0,
              label: Text('$_unreadCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Cá nhân & Thống kê',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              _loadData();
            },
            icon: const Icon(Icons.person_outline),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _scopes.map((s) => Tab(text: s['label'])).toList(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onSubmitted: (_) => _loadData(),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm theo tên công việc...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                _loadData();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Bộ lọc & Sắp xếp',
                  onPressed: _openFilterSheet,
                  icon: const Icon(Icons.tune),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.black87),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: _loadData,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _tasks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 56,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Chưa có công việc nào trong mục này',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _tasks.length,
                              itemBuilder: (context, index) {
                                final task = _tasks[index];
                                return TaskCard(
                                  task: task,
                                  onTap: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            TaskDetailScreen(taskId: task.id),
                                      ),
                                    );
                                    _loadData();
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const TaskCreateScreen()),
          );
          if (created == true) {
            _loadData();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm việc'),
      ),
    );
  }
}
