import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ErrorDialog - テキスト選択・コピー可能なエラーダイアログ
///
/// 使用例:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => ErrorDialog(
///     title: 'Firebaseエラー',
///     message: 'The query requires an index...',
///   ),
/// );
/// ```
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? details;
  final VoidCallback? onRetry;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.details,
    this.onRetry,
  });

  /// ErrorDialogを表示するヘルパーメソッド
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String? details,
    VoidCallback? onRetry,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        details: details,
        onRetry: onRetry,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullMessage = details != null ? '$message\n\n$details' : message;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 28),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 18))),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // エラーメッセージ（選択可能）
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: SelectableText(
                fullMessage,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Colors.red.shade900,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // ヒント
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'テキストを選択してコピーできます',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        // コピーボタン
        TextButton.icon(
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('コピー'),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: fullMessage));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('クリップボードにコピーしました'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
        // リトライボタン（オプション）
        if (onRetry != null)
          TextButton.icon(
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('再試行'),
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
          ),
        // 閉じるボタン
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}

/// AsyncError状態を表示するウィジェット
///
/// Riverpodの.whenでerror状態を表示する際に使用
///
/// 使用例:
/// ```dart
/// asyncValue.when(
///   data: (data) => ...,
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => AsyncErrorWidget(
///     error: error,
///     stackTrace: stack,
///     onRetry: () => ref.invalidate(provider),
///   ),
/// )
/// ```
class AsyncErrorWidget extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback? onRetry;
  final String? title;
  final bool compact;

  const AsyncErrorWidget({
    super.key,
    required this.error,
    this.stackTrace,
    this.onRetry,
    this.title,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact(context);
    }
    return _buildFull(context);
  }

  Widget _buildCompact(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 32),
          const SizedBox(height: 8),
          SelectableText(
            '$error',
            style: const TextStyle(color: Colors.red, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('再試行'),
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              title ?? 'エラーが発生しました',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SelectableText(
                      '$error',
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: '$error'));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('コピーしました'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    tooltip: 'コピー',
                    color: Colors.red.shade700,
                  ),
                ],
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('再試行'),
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
