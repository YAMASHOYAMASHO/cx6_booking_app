import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import '../models/reservation.dart';
import '../models/favorite_equipment.dart';
import '../models/favorite_reservation_template.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/reservation_viewmodel.dart';
import '../viewmodels/favorite_equipment_viewmodel.dart';
import '../viewmodels/favorite_reservation_template_viewmodel.dart';
import '../viewmodels/equipment_viewmodel.dart';
import '../config/auth_config.dart';
import '../viewmodels/location_viewmodel.dart';
import '../utils/error_handler.dart';
import '../services/google_calendar_service.dart';
import 'widgets/common/error_dialog.dart';
import 'template_edit_page.dart';
import 'reservation_form_page.dart';

/// マイページ
class MyPage extends ConsumerWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('ログインしていません')));
    }

    final myReservationsAsync = ref.watch(
      reservationsByUserProvider(currentUser.id),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('マイページ')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final padding = isMobile ? 8.0 : 16.0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // プロフィール設定カード
                _ProfileCard(user: currentUser),
                const SizedBox(height: 16),

                // パスワード変更カード
                const _PasswordCard(),
                const SizedBox(height: 16),

                // アカウント削除カード
                const _DeleteAccountCard(),
                const SizedBox(height: 16),

                // お気に入り装置セクション
                const _FavoriteEquipmentsSection(),
                const SizedBox(height: 16),

                // お気に入りテンプレートセクション
                const _FavoriteTemplatesSection(),
                const SizedBox(height: 16),

                // 自分の予約一覧
                const Text(
                  '今後の予約 (最大10件)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                myReservationsAsync.when(
                  data: (myReservations) {
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
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: AsyncErrorWidget(
                        error: error,
                        stackTrace: stack,
                        title: '予約の取得に失敗しました',
                        compact: true,
                        onRetry: () => ref.invalidate(
                          reservationsByUserProvider(currentUser.id),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
  final _colorCodeController = TextEditingController();
  Color _selectedColor = Colors.blue;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.name;
    if (widget.user.myColor != null) {
      _selectedColor = _parseColor(widget.user.myColor!);
      _colorCodeController.text = widget.user.myColor!;
    } else {
      _colorCodeController.text = _colorToHex(Colors.blue);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _colorCodeController.dispose();
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
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) {
        Color tempColor = _selectedColor;
        return AlertDialog(
          title: const Text('カラーを選択'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) {
                tempColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              displayThumbColor: true,
              enableAlpha: false,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedColor = tempColor;
                  _colorCodeController.text = _colorToHex(tempColor);
                });
                Navigator.of(context).pop();
              },
              child: const Text('選択'),
            ),
          ],
        );
      },
    );
  }

  void _updateColorFromCode(String hexCode) {
    try {
      final color = _parseColor(hexCode);
      setState(() {
        _selectedColor = color;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('無効なカラーコードです')));
    }
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

            // ユーザーID（読み取り専用）
            Text('ユーザーID', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(
              AuthConfig.emailToUserId(widget.user.email),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'メールアドレス: ${widget.user.email}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
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
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                  ),
                ),
                const SizedBox(width: 16),
                if (_isEditing) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _showColorPicker,
                          icon: const Icon(Icons.palette),
                          label: const Text('カラーピッカーで選択'),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _colorCodeController,
                          decoration: InputDecoration(
                            labelText: 'カラーコード',
                            hintText: '#FF5733',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.check),
                              onPressed: () {
                                _updateColorFromCode(_colorCodeController.text);
                              },
                            ),
                          ),
                          onSubmitted: _updateColorFromCode,
                        ),
                      ],
                    ),
                  ),
                ] else
                  Text(
                    _colorToHex(_selectedColor),
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'monospace',
                    ),
                  ),
              ],
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
                          _colorCodeController.text = widget.user.myColor!;
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

/// アカウント削除カード
class _DeleteAccountCard extends ConsumerWidget {
  const _DeleteAccountCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'アカウント削除',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'アカウントを削除すると、すべての予約、お気に入り装置、テンプレートが削除されます。この操作は元に戻せません。',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showFirstConfirmation(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.delete_forever),
                label: const Text('アカウントを削除'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFirstConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red),
            SizedBox(width: 8),
            Text('アカウント削除の確認'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('本当にアカウントを削除しますか？'),
            SizedBox(height: 16),
            Text(
              '以下のデータがすべて削除されます：',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• すべての予約'),
            Text('• お気に入り装置'),
            Text('• お気に入りテンプレート'),
            Text('• アカウント情報'),
            SizedBox(height: 16),
            Text(
              'この操作は取り消せません。',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSecondConfirmation(context, ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除を続行'),
          ),
        ],
      ),
    );
  }

  void _showSecondConfirmation(BuildContext context, WidgetRef ref) {
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.dangerous, color: Colors.red),
                SizedBox(width: 8),
                Text('最終確認'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '最終確認：「削除」と入力してください',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '「削除」と入力',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  confirmController.dispose();
                  Navigator.pop(dialogContext);
                },
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: confirmController.text == '削除'
                    ? () async {
                        Navigator.pop(dialogContext);
                        await _deleteAccount(context, ref);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('アカウントを削除'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    // ローディングダイアログを表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('アカウントを削除中...'),
          ],
        ),
      ),
    );

    try {
      await ref.read(authViewModelProvider.notifier).deleteAccount();

      if (context.mounted) {
        // ローディングダイアログを閉じる
        Navigator.pop(context);

        // 成功メッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('アカウントを削除しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        // ローディングダイアログを閉じる
        Navigator.pop(context);

        // エラーメッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('アカウントの削除に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 編集ボタン
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () async {
                      // 装置情報を取得
                      final equipmentsAsync = ref.read(equipmentsProvider);
                      final equipment = equipmentsAsync.value?.firstWhere(
                        (e) => e.id == reservation.equipmentId,
                        orElse: () => throw Exception('装置が見つかりません'),
                      );

                      if (equipment == null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('装置情報の取得に失敗しました')),
                          );
                        }
                        return;
                      }

                      // 予約編集画面へ遷移
                      if (context.mounted) {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ReservationFormPage(
                              equipment: equipment,
                              selectedDate: DateTime(
                                reservation.startTime.year,
                                reservation.startTime.month,
                                reservation.startTime.day,
                              ),
                              reservation: reservation,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  // 削除ボタン
                  IconButton(
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
                        try {
                          await ref
                              .read(reservationViewModelProvider.notifier)
                              .deleteReservation(
                                reservation.id,
                                reservation: reservation,
                              );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('予約を削除しました')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('削除に失敗しました: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              )
            : null,
      ),
    );
  }
}

/// お気に入り装置セクション
class _FavoriteEquipmentsSection extends ConsumerWidget {
  const _FavoriteEquipmentsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteDetailsAsync = ref.watch(favoriteEquipmentDetailsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber),
                    SizedBox(width: 8),
                    Text(
                      'お気に入り装置',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddFavoriteDialog(context, ref),
                  tooltip: '装置を追加',
                ),
              ],
            ),
            const SizedBox(height: 16),
            favoriteDetailsAsync.when(
              data: (favorites) {
                if (favorites.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'お気に入り装置がありません\n右上の＋ボタンから追加できます',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  onReorder: (oldIndex, newIndex) {
                    // リストを再構築
                    final reorderedFavorites = List<FavoriteEquipment>.from(
                      favorites.map((d) => d.favorite),
                    );

                    // 要素を移動
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final item = reorderedFavorites.removeAt(oldIndex);
                    reorderedFavorites.insert(newIndex, item);

                    // ViewModelに通知
                    ref
                        .read(favoriteEquipmentViewModelProvider.notifier)
                        .reorder(reorderedFavorites);
                  },
                  children: favorites.map((detail) {
                    return ListTile(
                      key: ValueKey(detail.favorite.id),
                      leading: const Icon(Icons.drag_handle),
                      title: Text(detail.favorite.equipmentName),
                      subtitle: Text(detail.favorite.locationName),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('お気に入りから削除'),
                              content: Text(
                                '「${detail.favorite.equipmentName}」をお気に入りから削除しますか？',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
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
                                .read(
                                  favoriteEquipmentViewModelProvider.notifier,
                                )
                                .removeFavorite(detail.favorite.id);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('お気に入りから削除しました')),
                              );
                            }
                          }
                        },
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'お気に入り装置取得エラー',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        '$error',
                        style: const TextStyle(
                          color: Colors.red,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFavoriteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _AddFavoriteEquipmentDialog(),
    );
  }
}

/// お気に入り装置追加ダイアログ
class _AddFavoriteEquipmentDialog extends ConsumerStatefulWidget {
  const _AddFavoriteEquipmentDialog();

  @override
  ConsumerState<_AddFavoriteEquipmentDialog> createState() =>
      _AddFavoriteEquipmentDialogState();
}

class _AddFavoriteEquipmentDialogState
    extends ConsumerState<_AddFavoriteEquipmentDialog> {
  String? _selectedLocationId;
  String? _selectedEquipmentId;

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(locationsProvider);
    final equipmentsAsync = ref.watch(equipmentsProvider);
    final favoritesAsync = ref.watch(favoriteEquipmentsProvider);

    return AlertDialog(
      title: const Text('お気に入り装置を追加'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ロケーション選択
              const Text(
                'ロケーション',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              locationsAsync.when(
                data: (locations) {
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedLocationId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'ロケーションを選択',
                    ),
                    items: locations
                        .map(
                          (location) => DropdownMenuItem(
                            value: location.id,
                            child: Text(location.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLocationId = value;
                        _selectedEquipmentId = null; // 装置選択をリセット
                      });
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => SelectableText(
                  'エラー: $error',
                  style: const TextStyle(
                    color: Colors.red,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 装置選択
              const Text('装置', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_selectedLocationId == null)
                const Text(
                  'まずロケーションを選択してください',
                  style: TextStyle(color: Colors.grey),
                )
              else
                equipmentsAsync.when(
                  data: (equipments) {
                    // 選択されたロケーションの装置のみフィルタ
                    final filteredEquipments = equipments
                        .where((e) => e.locationId == _selectedLocationId)
                        .toList();

                    // すでにお気に入りに登録されている装置を除外
                    final favoriteEquipmentIds = favoritesAsync.maybeWhen(
                      data: (favorites) =>
                          favorites.map((f) => f.equipmentId).toSet(),
                      orElse: () => <String>{},
                    );

                    final availableEquipments = filteredEquipments
                        .where((e) => !favoriteEquipmentIds.contains(e.id))
                        .toList();

                    if (availableEquipments.isEmpty) {
                      return const Text(
                        'このロケーションには追加可能な装置がありません',
                        style: TextStyle(color: Colors.grey),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedEquipmentId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '装置を選択',
                      ),
                      items: availableEquipments
                          .map(
                            (equipment) => DropdownMenuItem(
                              value: equipment.id,
                              child: Text(equipment.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedEquipmentId = value;
                        });
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => SelectableText(
                    'エラー: $error',
                    style: const TextStyle(
                      color: Colors.red,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _selectedEquipmentId == null
              ? null
              : () async {
                  try {
                    ErrorHandler.logDebug(
                      '[MyPage] お気に入り追加開始: selectedEquipmentId=$_selectedEquipmentId',
                    );
                    final equipments = equipmentsAsync.value;
                    if (equipments == null) {
                      ErrorHandler.logError('[MyPage] equipmentsがnull');
                      return;
                    }

                    final selectedEquipment = equipments.firstWhere(
                      (e) => e.id == _selectedEquipmentId,
                    );
                    ErrorHandler.logDebug(
                      '[MyPage] 選択された装置: ${selectedEquipment.name} (${selectedEquipment.id})',
                    );

                    ErrorHandler.logDebug('[MyPage] ViewModelのaddFavorite呼び出し');
                    await ref
                        .read(favoriteEquipmentViewModelProvider.notifier)
                        .addFavorite(selectedEquipment);
                    ErrorHandler.logDebug('[MyPage] ViewModelのaddFavorite完了');

                    if (context.mounted) {
                      Navigator.pop(context);
                      ErrorHandler.showSuccess(
                        context,
                        message: 'お気に入りに追加しました',
                      );
                    }
                  } catch (e) {
                    ErrorHandler.logError('[MyPage] エラー発生', error: e);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ErrorHandler.showError(
                        context,
                        message: 'お気に入り追加に失敗しました',
                        error: e,
                        displayType: ErrorDisplayType.snackBar,
                      );
                    }
                  }
                },
          child: const Text('追加'),
        ),
      ],
    );
  }
}

/// お気に入りテンプレートセクション
class _FavoriteTemplatesSection extends ConsumerWidget {
  const _FavoriteTemplatesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(favoriteReservationTemplatesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.playlist_add_check, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'お気に入りテンプレート',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TemplateEditPage(),
                      ),
                    );

                    if (result == true && context.mounted) {
                      // テンプレート作成成功時の処理
                      ref.invalidate(favoriteReservationTemplatesProvider);
                    }
                  },
                  tooltip: 'テンプレートを作成',
                ),
              ],
            ),
            const SizedBox(height: 16),
            templatesAsync.when(
              data: (templates) {
                if (templates.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'テンプレートがありません\n右上の＋ボタンから作成できます',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return Column(
                  children: templates.map((template) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.grid_on, color: Colors.green),
                        title: Text(template.name),
                        subtitle: Text(
                          '${template.slots.length}件の予約'
                          '${template.description != null && template.description!.isNotEmpty ? '\n${template.description}' : ''}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.play_arrow,
                                color: Colors.blue,
                              ),
                              tooltip: '実行',
                              onPressed: () {
                                _showExecuteDialog(context, ref, template);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: '編集',
                              onPressed: () async {
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => TemplateEditPage(
                                      templateId: template.id,
                                    ),
                                  ),
                                );

                                if (result == true && context.mounted) {
                                  ref.invalidate(
                                    favoriteReservationTemplatesProvider,
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: '削除',
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('テンプレート削除'),
                                    content: Text('「${template.name}」を削除しますか？'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('キャンセル'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
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
                                      .read(
                                        favoriteReservationTemplateViewModelProvider
                                            .notifier,
                                      )
                                      .deleteTemplate(template.id);

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('テンプレートを削除しました'),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'テンプレート取得エラー',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        '$error',
                        style: const TextStyle(
                          color: Colors.red,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExecuteDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic template,
  ) {
    showDialog(
      context: context,
      builder: (context) => _TemplateExecuteDialog(template: template),
    );
  }
}

/// テンプレート実行ダイアログ
class _TemplateExecuteDialog extends ConsumerStatefulWidget {
  final FavoriteReservationTemplate template;

  const _TemplateExecuteDialog({required this.template});

  @override
  ConsumerState<_TemplateExecuteDialog> createState() =>
      _TemplateExecuteDialogState();
}

class _TemplateExecuteDialogState
    extends ConsumerState<_TemplateExecuteDialog> {
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
          // テンプレート情報から Googleカレンダー用のデータを構築
          final template = widget.template;
          final slots = template.slots;

          // 装置名一覧
          final equipmentNames = slots
              .map((slot) => slot.equipmentName)
              .toList();

          // 備考一覧
          final notes = slots.map((slot) => slot.note).toList();

          // 最も早い開始時刻と最も遅い終了時刻を計算
          DateTime? earliestStart;
          DateTime? latestEnd;

          for (final slot in slots) {
            final startDateTime = slot.getStartDateTime(_baseDate);
            final endDateTime = slot.getEndDateTime(_baseDate);

            if (earliestStart == null ||
                startDateTime.isBefore(earliestStart)) {
              earliestStart = startDateTime;
            }
            if (latestEnd == null || endDateTime.isAfter(latestEnd)) {
              latestEnd = endDateTime;
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(result.message)),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 10),
              action: earliestStart != null && latestEnd != null
                  ? SnackBarAction(
                      label: 'Googleカレンダーに登録',
                      textColor: Colors.white,
                      onPressed: () {
                        GoogleCalendarService.addTemplateReservation(
                          templateName: template.name,
                          equipmentNames: equipmentNames,
                          earliestStartTime: earliestStart!,
                          latestEndTime: latestEnd!,
                          notes: notes,
                        );
                      },
                    )
                  : null,
            ),
          );
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
