import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/reservation.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/reservation_viewmodel.dart';

/// マイページ
class MyPage extends ConsumerWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    final allReservationsAsync = ref.watch(reservationsProvider);

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('ログインしていません')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('マイページ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // プロフィール設定カード
            _ProfileCard(user: currentUser),
            const SizedBox(height: 16),

            // パスワード変更カード
            const _PasswordCard(),
            const SizedBox(height: 16),

            // 自分の予約一覧
            const Text(
              '自分の予約',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            allReservationsAsync.when(
              data: (allReservations) {
                // 自分の予約のみフィルタ
                final myReservations =
                    allReservations
                        .where((r) => r.userId == currentUser.id)
                        .toList()
                      ..sort((a, b) => b.startTime.compareTo(a.startTime));

                if (myReservations.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('予約がありません'),
                    ),
                  );
                }

                return Column(
                  children: myReservations
                      .map(
                        (reservation) =>
                            _ReservationCard(reservation: reservation),
                      )
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('エラー: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// プロフィール設定カード
class _ProfileCard extends ConsumerStatefulWidget {
  final dynamic user;

  const _ProfileCard({required this.user});

  @override
  ConsumerState<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends ConsumerState<_ProfileCard> {
  final _nameController = TextEditingController();
  Color _selectedColor = Colors.blue;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.name;
    if (widget.user.myColor != null) {
      _selectedColor = _parseColor(widget.user.myColor!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
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
                  'プロフィール設定',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (!_isEditing)
                  TextButton.icon(
                    onPressed: () => setState(() => _isEditing = true),
                    icon: const Icon(Icons.edit),
                    label: const Text('編集'),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // メールアドレス（編集不可）
            Text('メールアドレス', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(widget.user.email, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),

            // 名前
            Text('名前', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            if (_isEditing)
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '名前を入力',
                ),
              )
            else
              Text(widget.user.name, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),

            // マイカラー
            Text('マイカラー', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            if (_isEditing)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                      Colors.blue,
                      Colors.red,
                      Colors.green,
                      Colors.orange,
                      Colors.purple,
                      Colors.pink,
                      Colors.teal,
                      Colors.amber,
                    ].map((color) {
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedColor == color
                                  ? Colors.black
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _selectedColor,
                  shape: BoxShape.circle,
                ),
              ),

            if (_isEditing) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _nameController.text = widget.user.name;
                        if (widget.user.myColor != null) {
                          _selectedColor = _parseColor(widget.user.myColor!);
                        }
                        _isEditing = false;
                      });
                    },
                    child: const Text('キャンセル'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: authState.isLoading
                        ? null
                        : () async {
                            await ref
                                .read(authViewModelProvider.notifier)
                                .updateUserProfile(
                                  userId: widget.user.id,
                                  name: _nameController.text.trim(),
                                  myColor: _colorToHex(_selectedColor),
                                );

                            if (mounted) {
                              setState(() => _isEditing = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('プロフィールを更新しました')),
                              );
                            }
                          },
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('保存'),
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

/// パスワード変更カード
class _PasswordCard extends ConsumerStatefulWidget {
  const _PasswordCard();

  @override
  ConsumerState<_PasswordCard> createState() => _PasswordCardState();
}

class _PasswordCardState extends ConsumerState<_PasswordCard> {
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

/// 予約カード
class _ReservationCard extends ConsumerWidget {
  final Reservation reservation;

  const _ReservationCard({required this.reservation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('yyyy/MM/dd (E)', 'ja');
    final timeFormat = DateFormat('HH:mm');

    // 過去の予約かどうか
    final isPast = reservation.endTime.isBefore(DateTime.now());

    return Card(
      color: isPast ? Colors.grey[100] : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPast ? Colors.grey : Colors.blue,
          child: Icon(
            isPast ? Icons.history : Icons.event,
            color: Colors.white,
          ),
        ),
        title: Text(
          reservation.equipmentName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isPast ? Colors.grey[600] : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateFormat.format(reservation.startTime)),
            Text(
              '${timeFormat.format(reservation.startTime)} - ${timeFormat.format(reservation.endTime)}',
            ),
            if (reservation.note != null && reservation.note!.isNotEmpty)
              Text('備考: ${reservation.note}'),
          ],
        ),
        trailing: !isPast
            ? IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('予約の削除'),
                      content: const Text('この予約を削除しますか？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            '削除',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await ref
                        .read(reservationViewModelProvider.notifier)
                        .deleteReservation(reservation.id);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('予約を削除しました')),
                      );
                    }
                  }
                },
              )
            : null,
      ),
    );
  }
}
