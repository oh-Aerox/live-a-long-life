import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/db/app_database.dart';
import '../data/repositories/profile_repository.dart';

/// 基本资料（D-18）：每项都可以填写、跳过或选择不愿透露，
/// 修改追加新版本，历史保留（schema §4.1）。
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.services});

  final AppServices services;

  static const labels = <String, String>{
    'full_name': '姓名（只用于发送前遮蔽）',
    'birth_year_month': '出生年月',
    'sex_at_birth': '生理性别',
    'gender_identity': '性别认同（可选）',
    'height_cm': '身高（厘米）',
    'exercise_preferences': '运动爱好',
    'chronic_conditions': '慢性病',
    'medications': '长期用药',
    'allergies': '过敏',
    'family_history': '家族病史',
    'smoking': '吸烟情况',
    'alcohol': '饮酒情况',
  };

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, (ProfileField, Object?)>? _current;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final map = <String, (ProfileField, Object?)>{};
    for (final key in ProfileRepository.fieldKeys) {
      final row = await widget.services.profile.current(key);
      if (row != null) map[key] = row;
    }
    if (mounted) setState(() => _current = map);
  }

  String _subtitle(String key) {
    final row = _current?[key];
    if (row == null) return '未填写';
    switch (row.$1.state) {
      case ProfileFieldState.skipped:
        return '已跳过';
      case ProfileFieldState.declined:
        return '不愿透露';
      case ProfileFieldState.provided:
        return '${row.$2}';
    }
  }

  Future<void> _editField(String key) async {
    final row = _current?[key];
    final controller = TextEditingController(
        text: row != null && row.$1.state == ProfileFieldState.provided
            ? '${row.$2}'
            : '');
    final result = await showDialog<(ProfileFieldState, String?)>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ProfilePage.labels[key] ?? key),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '填写内容'),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, (ProfileFieldState.declined, null)),
            child: const Text('不愿透露'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, (ProfileFieldState.skipped, null)),
            child: const Text('跳过'),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) {
                Navigator.pop(context);
              } else {
                Navigator.pop(context, (ProfileFieldState.provided, text));
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    await widget.services.profile
        .setField(key, value: result.$2, state: result.$1);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('基本资料')),
      body: _current == null
          ? const Center(child: CircularProgressIndicator.adaptive())
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text('每一项都可以跳过。资料只保存在本机。',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),
                for (final key in ProfileRepository.fieldKeys)
                  ListTile(
                    title: Text(ProfilePage.labels[key] ?? key),
                    subtitle: Text(_subtitle(key)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _editField(key),
                  ),
              ],
            ),
    );
  }
}
