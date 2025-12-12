import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// エラー表示タイプ
enum ErrorDisplayType {
  /// 軽微なエラー向け（バリデーションエラーなど）
  snackBar,

  /// 重要なエラー向け（Firebase、ネットワークエラーなど）
  dialog,
}

/// ErrorHandler - 統一されたエラー処理システム
///
/// 使用例:
/// ```dart
/// try {
///   await someAsyncOperation();
/// } catch (e, stack) {
///   ErrorHandler.showError(
///     context,
///     message: 'データの取得に失敗しました',
///     error: e,
///     stackTrace: stack,
///     displayType: ErrorDisplayType.dialog,
///   );
/// }
/// ```
class ErrorHandler {
  /// エラーを表示（自動でコンソールログ出力）
  ///
  /// [context] BuildContext
  /// [message] ユーザーに表示するメッセージ
  /// [title] ダイアログのタイトル（displayType.dialogの場合のみ使用）
  /// [error] 元のエラーオブジェクト
  /// [stackTrace] スタックトレース
  /// [displayType] 表示タイプ（snackBar or dialog）
  static void showError(
    BuildContext context, {
    required String message,
    String? title,
    Object? error,
    StackTrace? stackTrace,
    ErrorDisplayType displayType = ErrorDisplayType.snackBar,
  }) {
    // コンソールにログ出力
    logError(message, error: error, stackTrace: stackTrace);

    // エラーメッセージを構築
    final fullMessage = error != null ? '$message\n\n詳細: $error' : message;

    switch (displayType) {
      case ErrorDisplayType.snackBar:
        _showCopyableSnackBar(context, message: fullMessage, isError: true);
        break;
      case ErrorDisplayType.dialog:
        _showErrorDialog(context, title: title ?? 'エラー', message: fullMessage);
        break;
    }
  }

  /// 成功メッセージをSnackBarで表示
  static void showSuccess(BuildContext context, {required String message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 情報メッセージをSnackBarで表示
  static void showInfo(BuildContext context, {required String message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// コンソールにエラーをログ出力
  ///
  /// デバッグビルドでのみ出力される
  static void logError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    debugPrint('🔴 [ERROR] $message');
    if (error != null) {
      debugPrint('🔴 [ERROR] Detail: $error');
    }
    if (stackTrace != null) {
      debugPrint('🔴 [ERROR] StackTrace: $stackTrace');
    }
  }

  /// デバッグログ出力
  static void logDebug(String message) {
    debugPrint('🔵 [DEBUG] $message');
  }

  /// 警告ログ出力
  static void logWarning(String message) {
    debugPrint('🟡 [WARNING] $message');
  }

  /// クリップボードにテキストをコピー
  static Future<void> copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('クリップボードにコピーしました'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// コピー可能なSnackBarを表示
  static void _showCopyableSnackBar(
    BuildContext context, {
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 6),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Expanded(
              child: Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.white, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: message));
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('コピーしました'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              tooltip: 'コピー',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : null,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action: SnackBarAction(
          label: '詳細',
          textColor: Colors.white,
          onPressed: () {
            _showErrorDialog(context, title: 'エラー詳細', message: message);
          },
        ),
      ),
    );
  }

  /// エラーダイアログを表示
  static void _showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SelectableText(
                  message,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('コピー'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: message));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('クリップボードにコピーしました'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}
