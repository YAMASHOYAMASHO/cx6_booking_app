import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../config/auth_config.dart';

/// ログイン画面
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController(); // emailController から変更
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true; // パスワード表示/非表示の状態

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // タイトル
                const Text(
                  '装置予約システム',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // 新規登録時の説明
                if (_isSignUp) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '※ 事前に申請済みのユーザーのみアカウント作成が可能です。\n'
                            '学籍番号が登録されていない場合は管理者にお問い合わせください。',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade900,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                // 名前（サインアップ時のみ）
                if (_isSignUp) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '名前',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    autofillHints: const [AutofillHints.name],
                    onFieldSubmitted: (_) => _submit(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '名前を入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                // ユーザーID（学籍番号 または メールアドレス）
                TextFormField(
                  controller: _userIdController,
                  decoration: InputDecoration(
                    labelText: AuthConfig.getUserIdLabel(),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.badge),
                    hintText: AuthConfig.getUserIdPlaceholder(),
                    helperText: AuthConfig.getUserIdHelpText(),
                    helperMaxLines: 2,
                  ),
                  keyboardType: TextInputType.text,
                  autofillHints: const [AutofillHints.username],
                  onFieldSubmitted: (_) => _submit(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '学籍番号またはメールアドレスを入力してください';
                    }
                    // @が含まれている場合はメールアドレスとして検証
                    if (value.contains('@')) {
                      if (!value.contains('.')) {
                        return '有効なメールアドレスを入力してください';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // パスワード
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'パスワード',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      tooltip: _obscurePassword ? 'パスワードを表示' : 'パスワードを隠す',
                    ),
                  ),
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _submit(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'パスワードを入力してください';
                    }
                    if (value.length < 6) {
                      return 'パスワードは6文字以上にしてください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // ログイン/サインアップボタン
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: authState.isLoading
                      ? const CircularProgressIndicator()
                      : Text(_isSignUp ? '新規登録' : 'ログイン'),
                ),
                const SizedBox(height: 16),
                // 切り替えボタン
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                    });
                  },
                  child: Text(
                    _isSignUp ? 'すでにアカウントをお持ちの方はこちら' : 'アカウントをお持ちでない方はこちら',
                  ),
                ),
                // エラーメッセージ
                if (authState.hasError)
                  _ErrorDisplay(
                    error: _getErrorMessage(authState.error.toString()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // ユーザーID（学籍番号）を取得
      final studentId = _userIdController.text.trim();
      // メールアドレスに変換
      final email = AuthConfig.userIdToEmail(studentId);

      if (_isSignUp) {
        await ref
            .read(authViewModelProvider.notifier)
            .signUpWithEmail(
              email,
              _passwordController.text,
              _nameController.text.trim(),
              studentId, // 学籍番号を追加
            );
      } else {
        await ref
            .read(authViewModelProvider.notifier)
            .signInWithEmail(email, _passwordController.text);
      }
    } catch (e) {
      // エラーは authViewModelProvider の状態で処理される
    }
  }

  /// エラーメッセージを分かりやすく変換
  String _getErrorMessage(String error) {
    // 事前登録関連のエラー
    if (error.contains('登録が許可されていません') ||
        error.contains('この学籍番号は登録が許可されていません')) {
      return '【登録許可なし】この学籍番号は事前登録されていません。\n'
          '管理者に学籍番号の登録を依頼してください。';
    }

    // 既に登録済み
    if (error.contains('既に登録済み') || error.contains('already registered')) {
      return '【登録済み】この学籍番号は既に使用されています。\n'
          'ログイン画面からログインしてください。';
    }

    // Firebase認証エラーを分かりやすいメッセージに変換
    if (error.contains('invalid-email') ||
        error.contains('user-not-found') ||
        error.contains('wrong-password') ||
        error.contains('invalid-credential')) {
      return '【認証エラー】学籍番号またはパスワードが間違っています。';
    } else if (error.contains('email-already-in-use')) {
      return '【重複エラー】この学籍番号は既に使用されています。\n'
          '別の学籍番号をお使いいただくか、ログインしてください。';
    } else if (error.contains('weak-password')) {
      return '【パスワードエラー】パスワードが弱すぎます。\n'
          '6文字以上で設定してください。';
    } else if (error.contains('network-request-failed')) {
      return '【ネットワークエラー】接続を確認してください。';
    } else if (error.contains('too-many-requests')) {
      return '【試行回数超過】ログイン試行回数が多すぎます。\n'
          'しばらく待ってから再度お試しください。';
    } else if (error.contains('permission-denied') ||
        error.contains('PERMISSION_DENIED')) {
      return '【権限エラー】データベースへのアクセスが拒否されました。\n'
          '学籍番号が事前登録されているか確認してください。';
    }

    // その他のエラー（詳細を含める）
    return '【エラー】${_isSignUp ? "アカウント作成" : "ログイン"}に失敗しました。\n'
        '詳細: ${error.length > 100 ? "${error.substring(0, 100)}..." : error}';
  }
}

/// エラー表示ウィジェット
class _ErrorDisplay extends StatelessWidget {
  final String error;

  const _ErrorDisplay({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade400, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'エラーが発生しました',
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              error,
              style: TextStyle(
                color: Colors.red.shade900,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
