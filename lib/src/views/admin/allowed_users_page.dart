import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/allowed_user.dart';
import '../../viewmodels/allowed_user_viewmodel.dart';
import '../../repositories/allowed_user_repository.dart';
import 'allowed_users_csv_dialog.dart';

/// 事前登録ユーザー管理画面
class AllowedUsersPage extends ConsumerStatefulWidget {
  const AllowedUsersPage({super.key});

  @override
  ConsumerState<AllowedUsersPage> createState() => _AllowedUsersPageState();
}

class _AllowedUsersPageState extends ConsumerState<AllowedUsersPage> {
  final Set<String> _selectedUserIds = {};
  bool _showOnlyUnregistered = false;

  @override
  Widget build(BuildContext context) {
    final allowedUsersAsync = _showOnlyUnregistered
        ? ref.watch(unregisteredAllowedUsersProvider)
        : ref.watch(allowedUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('事前登録管理'),
        actions: [
          // フィルター切り替え
          IconButton(
            icon: Icon(
              _showOnlyUnregistered
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
            ),
            tooltip: _showOnlyUnregistered ? '全て表示' : '未登録のみ表示',
            onPressed: () {
              setState(() {
                _showOnlyUnregistered = !_showOnlyUnregistered;
                _selectedUserIds.clear();
              });
            },
          ),
          // 個別追加
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: '個別追加',
            onPressed: () => _showAddDialog(),
          ),
          // CSV一括追加
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'CSV一括追加',
            onPressed: () => _showCsvDialog(),
          ),
          // 選択削除
          if (_selectedUserIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: '選択削除',
              onPressed: () => _showBulkDeleteConfirmation(),
            ),
        ],
      ),
      body: allowedUsersAsync.when(
        data: (users) => _buildUserList(users),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('エラー: $error')),
      ),
    );
  }

  Widget _buildUserList(List<AllowedUser> users) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _showOnlyUnregistered ? '未登録のユーザーがいません' : '事前登録ユーザーがいません',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showCsvDialog(),
              icon: const Icon(Icons.upload_file),
              label: const Text('CSVで一括追加'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: Checkbox(
              value: _selectedUserIds.contains(user.studentId),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selectedUserIds.add(user.studentId);
                  } else {
                    _selectedUserIds.remove(user.studentId);
                  }
                });
              },
            ),
            title: Row(
              children: [
                Text(
                  user.studentId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 8),
                if (user.registered)
                  const Chip(
                    label: Text('登録済み', style: TextStyle(fontSize: 10)),
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 4),
                  )
                else
                  const Chip(
                    label: Text('未登録', style: TextStyle(fontSize: 10)),
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(horizontal: 4),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('メール: ${user.email}'),
                Text(
                  '許可日: ${DateFormat('yyyy/MM/dd HH:mm').format(user.allowedAt)}',
                ),
                if (user.note != null && user.note!.isNotEmpty)
                  Text('メモ: ${user.note}'),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (action) => _handleUserAction(action, user),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('編集'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('削除'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleUserAction(String action, AllowedUser user) async {
    switch (action) {
      case 'edit':
        await _showEditDialog(user);
        break;
      case 'delete':
        await _deleteUser(user);
        break;
    }
  }

  Future<void> _showAddDialog() async {
    final studentIdController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('事前登録追加'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: studentIdController,
                decoration: const InputDecoration(
                  labelText: '学籍番号',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '学籍番号を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'メモ（任意）',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final studentId = studentIdController.text.trim();
                final email = '$studentId@stu.kobe-u.ac.jp';
                final allowedUser = AllowedUser(
                  studentId: studentId,
                  email: email,
                  allowedAt: DateTime.now(),
                  registered: false,
                  note: noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim(),
                );

                try {
                  await ref
                      .read(allowedUserRepositoryProvider)
                      .addAllowedUser(allowedUser);

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$studentId を追加しました')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('エラー: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(AllowedUser user) async {
    final noteController = TextEditingController(text: user.note ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user.studentId} の編集'),
        content: TextFormField(
          controller: noteController,
          decoration: const InputDecoration(
            labelText: 'メモ',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedUser = user.copyWith(
                note: noteController.text.trim().isEmpty
                    ? null
                    : noteController.text.trim(),
              );

              try {
                await ref
                    .read(allowedUserRepositoryProvider)
                    .addAllowedUser(updatedUser);

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('更新しました')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('エラー: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(AllowedUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: Text('${user.studentId} を削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(allowedUserRepositoryProvider)
            .deleteAllowedUser(user.studentId);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${user.studentId} を削除しました')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラー: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _showBulkDeleteConfirmation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('一括削除確認'),
        content: Text('選択した${_selectedUserIds.length}件を削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(allowedUserRepositoryProvider)
            .deleteAllowedUsers(_selectedUserIds.toList());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${_selectedUserIds.length}件削除しました')),
          );
          setState(() {
            _selectedUserIds.clear();
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラー: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _showCsvDialog() async {
    await showDialog(
      context: context,
      builder: (context) => const AllowedUsersCsvDialog(),
    );
  }
}
