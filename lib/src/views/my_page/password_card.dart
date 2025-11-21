import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/auth_viewmodel.dart';

/// パスワード変更カード
class PasswordCard extends ConsumerStatefulWidget {
  const PasswordCard({super.key});

  @override
  ConsumerState<PasswordCard> createState() => _PasswordCardState();
}

class _PasswordCardState extends ConsumerState<PasswordCard> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isChangingPassword = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'パスワード変更',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (!_isChangingPassword)
                  TextButton.icon(
                    onPressed: () => setState(() => _isChangingPassword = true),
                    icon: const Icon(Icons.lock),
                    label: const Text('変更'),
                  ),
              ],
            ),

            if (_isChangingPassword) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: '新しいパスワード',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: '新しいパスワード（確認）',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _newPasswordController.clear();
                        _confirmPasswordController.clear();
                        _isChangingPassword = false;
                      });
                    },
                    child: const Text('キャンセル'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: authState.isLoading
                        ? null
                        : () async {
                            final newPassword = _newPasswordController.text;
                            final confirmPassword =
                                _confirmPasswordController.text;

                            if (newPassword.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('新しいパスワードを入力してください'),
                                ),
                              );
                              return;
                            }

                            if (newPassword.length < 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('パスワードは6文字以上にしてください'),
                                ),
                              );
                              return;
                            }

                            if (newPassword != confirmPassword) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('パスワードが一致しません')),
                              );
                              return;
                            }

                            await ref
                                .read(authViewModelProvider.notifier)
                                .changePassword(newPassword);

                            if (mounted) {
                              setState(() {
                                _newPasswordController.clear();
                                _confirmPasswordController.clear();
                                _isChangingPassword = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('パスワードを変更しました')),
                              );
                            }
                          },
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('変更'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
