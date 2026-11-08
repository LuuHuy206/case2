import 'package:flutter/material.dart';
import 'services/api_client.dart';
import 'screens/auth/login_screen.dart';
import 'screens/tasks/task_list_screen.dart';

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  Future<bool> _hasToken() async {
    final token = await ApiClient.getToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskManager - Lưu Nhật Huy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2563EB),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: FutureBuilder<bool>(
        future: _hasToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data == true
              ? const TaskListScreen()
              : const LoginScreen();
        },
      ),
    );
  }
}
