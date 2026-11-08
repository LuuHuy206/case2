import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class UserSelector extends StatefulWidget {
  final List<UserModel> initialSelected;
  final ValueChanged<List<UserModel>> onChanged;

  const UserSelector({
    super.key,
    this.initialSelected = const [],
    required this.onChanged,
  });

  @override
  State<UserSelector> createState() => _UserSelectorState();
}

class _UserSelectorState extends State<UserSelector> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<UserModel> _results = [];
  late List<UserModel> _selected;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _selected = List<UserModel>.from(widget.initialSelected);
    _search('');
  }

  Future<void> _search(String q) async {
    setState(() => _searching = true);
    try {
      final users = await UserService.searchUsers(q);
      if (!mounted) return;
      setState(() {
        _results = users;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _searching = false);
    }
  }

  void _toggleUser(UserModel user) {
    setState(() {
      final idx = _selected.indexWhere((u) => u.id == user.id);
      if (idx >= 0) {
        _selected.removeAt(idx);
      } else {
        _selected.add(user);
      }
    });
    widget.onChanged(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Tìm theo tên hoặc email...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => _search(_searchCtrl.text),
                  ),
          ),
          onChanged: _search,
        ),
        const SizedBox(height: 12),
        if (_selected.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _selected
                .map(
                  (u) => Chip(
                    label: Text('${u.fullName} (${u.email})'),
                    onDeleted: () => _toggleUser(u),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
        ],
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 240),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final u = _results[index];
              final isSelected = _selected.any((s) => s.id == u.id);
              return CheckboxListTile(
                value: isSelected,
                title: Text(u.fullName),
                subtitle: Text(u.email),
                onChanged: (_) => _toggleUser(u),
              );
            },
          ),
        ),
      ],
    );
  }
}
