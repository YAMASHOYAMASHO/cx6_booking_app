import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:csv/csv.dart';
import '../../repositories/allowed_user_repository.dart';

/// CSV一括追加ダイアログ
class AllowedUsersCsvDialog extends ConsumerStatefulWidget {
  const AllowedUsersCsvDialog({super.key});

  @override
  ConsumerState<AllowedUsersCsvDialog> createState() =>
      _AllowedUsersCsvDialogState();
}

class _AllowedUsersCsvDialogState extends ConsumerState<AllowedUsersCsvDialog> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('CSV一括追加'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CSVフォーマット:\n学籍番号,メモ',
              style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 8),
            const Text(
              '例:\n123456,情報科学科\n234567,電気電子工学科',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'CSVデータを貼り付け',
                border: OutlineInputBorder(),
                hintText: '123456,情報科学科\n234567,電気電子工学科',
              ),
              maxLines: 10,
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _result!.contains('エラー')
                      ? Colors.red[50]
                      : Colors.green[50],
                  border: Border.all(
                    color: _result!.contains('エラー') ? Colors.red : Colors.green,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(_result!),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _import,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('インポート'),
        ),
      ],
    );
  }

  Future<void> _import() async {
    if (_controller.text.trim().isEmpty) {
      setState(() {
        _result = 'エラー: CSVデータを入力してください';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      // CSVをパース
      final csvData = const CsvToListConverter().convert(_controller.text);

      // データを変換
      final List<Map<String, String>> users = [];
      for (final row in csvData) {
        if (row.isEmpty) continue;

        final studentId = row[0].toString().trim();
        final note = row.length > 1 ? row[1].toString().trim() : '';

        if (studentId.isNotEmpty) {
          users.add({'studentId': studentId, 'note': note});
        }
      }

      if (users.isEmpty) {
        setState(() {
          _result = 'エラー: 有効なデータがありません';
          _isLoading = false;
        });
        return;
      }

      // 一括追加
      final count = await ref
          .read(allowedUserRepositoryProvider)
          .addAllowedUsersFromCsv(users);

      setState(() {
        _result = '成功: $count件追加しました';
        _isLoading = false;
        _controller.clear();
      });
    } catch (e) {
      setState(() {
        _result = 'エラー: $e';
        _isLoading = false;
      });
    }
  }
}
