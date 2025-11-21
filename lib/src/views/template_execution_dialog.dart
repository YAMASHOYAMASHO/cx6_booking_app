import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../viewmodels/favorite_reservation_template_viewmodel.dart';
import '../models/favorite_reservation_template.dart';

/// テンプレート実行ダイアログ
class TemplateExecutionDialog extends ConsumerStatefulWidget {
  final FavoriteReservationTemplate template;

  const TemplateExecutionDialog({super.key, required this.template});

  @override
  ConsumerState<TemplateExecutionDialog> createState() =>
      _TemplateExecutionDialogState();
}

class _TemplateExecutionDialogState
    extends ConsumerState<TemplateExecutionDialog> {
  DateTime _baseDate = DateTime.now();
  bool _isChecking = false;
  bool _isExecuting = false;
  List<dynamic>? _conflicts;

  @override
  void initState() {
    super.initState();
    _checkConflicts();
  }

  Future<void> _checkConflicts() async {
    setState(() => _isChecking = true);

    try {
      final viewModel = ref.read(
        favoriteReservationTemplateViewModelProvider.notifier,
      );
      final conflicts = await viewModel.checkConflicts(
        widget.template.id,
        _baseDate,
      );

      if (mounted) {
        setState(() {
          _conflicts = conflicts;
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChecking = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('競合チェックエラー: $e')));
      }
    }
  }

  Future<void> _execute({bool skipConflicts = false}) async {
    setState(() => _isExecuting = true);

    try {
      final viewModel = ref.read(
        favoriteReservationTemplateViewModelProvider.notifier,
      );
      final result = await viewModel.executeTemplate(
        widget.template,
        _baseDate,
        skipConflicts: skipConflicts,
      );

      if (mounted) {
        Navigator.of(context).pop();

        if (result.success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(result.message)));
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('実行失敗'),
              content: Text(result.message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('閉じる'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExecuting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('実行エラー: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy年MM月dd日(E)', 'ja_JP');

    return AlertDialog(
      title: Text('「${widget.template.name}」を実行'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '基準日を選択',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _baseDate,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 30),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    locale: const Locale('ja', 'JP'),
                  );

                  if (date != null) {
                    setState(() {
                      _baseDate = date;
                    });
                    _checkConflicts();
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(dateFormat.format(_baseDate)),
                ),
              ),
              const SizedBox(height: 16),

              if (_isChecking)
                const Center(child: CircularProgressIndicator())
              else if (_conflicts != null) ...[
                const Text(
                  '競合チェック結果',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (_conflicts!.isEmpty)
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('競合なし。実行可能です。'),
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              '${_conflicts!.length}件の競合があります',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '競合をスキップして実行するか、基準日を変更してください。',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ], // if (_conflicts != null) の終わり
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),

        if (_conflicts != null && _conflicts!.isNotEmpty)
          ElevatedButton(
            onPressed: _isExecuting
                ? null
                : () => _execute(skipConflicts: true),
            child: _isExecuting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('競合をスキップして実行'),
          ),

        ElevatedButton(
          onPressed:
              _isExecuting || (_conflicts != null && _conflicts!.isNotEmpty)
              ? null
              : () => _execute(),
          child: _isExecuting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('実行'),
        ),
      ],
    );
  }
}
