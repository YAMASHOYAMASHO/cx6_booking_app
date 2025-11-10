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
                const SizedBox(height: 48),
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
      // ユーザーIDをメールアドレスに変換
      final email = AuthConfig.userIdToEmail(_userIdController.text.trim());

      if (_isSignUp) {
        await ref
            .read(authViewModelProvider.notifier)
            .signUpWithEmail(
              email,
              _passwordController.text,
              _nameController.text.trim(),
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
    // Firebase認証エラーを分かりやすいメッセージに変換
    if (error.contains('invalid-email') ||
        error.contains('user-not-found') ||
        error.contains('wrong-password') ||
        error.contains('invalid-credential')) {
      return 'メールアドレスまたはパスワードが間違っています';
    } else if (error.contains('email-already-in-use')) {
      return 'このメールアドレスは既に使用されています';
    } else if (error.contains('weak-password')) {
      return 'パスワードが弱すぎます。6文字以上で設定してください';
    } else if (error.contains('network-request-failed')) {
      return 'ネットワークエラーが発生しました。接続を確認してください';
    } else if (error.contains('too-many-requests')) {
      return 'ログイン試行回数が多すぎます。しばらく待ってから再度お試しください';
    }
    return 'ログインに失敗しました。入力内容をご確認ください';
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(error, style: TextStyle(color: Colors.red.shade900)),
          ),
        ],
      ),
    );
  }
}
