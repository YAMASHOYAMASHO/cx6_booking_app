import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/reservation.dart';
import '../models/equipment.dart';
import '../repositories/reservation_repository.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/reservation_viewmodel.dart';

/// 予約フォーム画面
class ReservationFormPage extends ConsumerStatefulWidget {
  final Equipment equipment;
  final DateTime selectedDate;
  final Reservation? reservation; // 編集時は既存の予約を渡す
  final DateTime? initialStartTime; // 初期開始時刻（タイムラインからのドラッグ用）
  final DateTime? initialEndTime; // 初期終了時刻（タイムラインからのドラッグ用）

  const ReservationFormPage({
    super.key,
    required this.equipment,
    required this.selectedDate,
    this.reservation,
    this.initialStartTime,
    this.initialEndTime,
  });

  @override
  ConsumerState<ReservationFormPage> createState() =>
      _ReservationFormPageState();
}

class _ReservationFormPageState extends ConsumerState<ReservationFormPage> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _startTime;
  late DateTime _endTime;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.reservation != null) {
      _startTime = widget.reservation!.startTime;
      _endTime = widget.reservation!.endTime;
      _noteController.text = widget.reservation!.note ?? '';
    } else if (widget.initialStartTime != null &&
        widget.initialEndTime != null) {
      // タイムラインからのドラッグで指定された時刻を使用
      _startTime = widget.initialStartTime!;
      _endTime = widget.initialEndTime!;
    } else {
      _startTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        9,
        0,
      );
      _endTime = _startTime.add(const Duration(hours: 1));
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(widget.reservation == null ? '新規予約' : '予約編集')),
      body: currentUser == null
          ? const Center(child: Text('ユーザー情報を読み込んでいます...'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 装置名
                    Text(
                      '装置: ${widget.equipment.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 日付
                    Text(
                      '日付: ${DateFormat('yyyy年M月d日(E)', 'ja_JP').format(widget.selectedDate)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    // 開始時刻
                    _buildTimePicker(
                      label: '開始時刻',
                      time: _startTime,
                      onChanged: (time) {
                        setState(() {
                          _startTime = time;
                          if (_endTime.isBefore(_startTime)) {
                            _endTime = _startTime.add(const Duration(hours: 1));
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // 終了時刻
                    _buildTimePicker(
                      label: '終了時刻',
                      time: _endTime,
                      onChanged: (time) {
                        setState(() {
                          _endTime = time;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // メモ
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'メモ（任意）',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    // 保存ボタン
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            _saveReservation(currentUser.id, currentUser.name),
                        child: const Text('予約を保存'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required DateTime time,
    required Function(DateTime) onChanged,
  }) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 16),
        DropdownButton<int>(
          value: time.hour,
          items: List.generate(24, (i) => i).map((hour) {
            return DropdownMenuItem(
              value: hour,
              child: Text(hour.toString().padLeft(2, '0')),
            );
          }).toList(),
          onChanged: (hour) {
            if (hour != null) {
              onChanged(
                DateTime(time.year, time.month, time.day, hour, time.minute),
              );
            }
          },
        ),
        const Text(' : '),
        DropdownButton<int>(
          value: time.minute,
          items: List.generate(12, (i) => i * 5).map((minute) {
            return DropdownMenuItem(
              value: minute,
              child: Text(minute.toString().padLeft(2, '0')),
            );
          }).toList(),
          onChanged: (minute) {
            if (minute != null) {
              onChanged(
                DateTime(time.year, time.month, time.day, time.hour, minute),
              );
            }
          },
        ),
      ],
    );
  }

  Future<void> _saveReservation(String userId, String userName) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_endTime.isBefore(_startTime) ||
        _endTime.isAtSameMomentAs(_startTime)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('終了時刻は開始時刻より後にしてください')));
      return;
    }

    // ローディング表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('予約を保存中...'),
              ],
            ),
          ),
        ),
      ),
    );

    final reservation = Reservation(
      id: widget.reservation?.id ?? '',
      equipmentId: widget.equipment.id,
      equipmentName: widget.equipment.name,
      userId: userId,
      startTime: _startTime,
      endTime: _endTime,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      createdAt: widget.reservation?.createdAt ?? DateTime.now(),
    );

    try {
      if (widget.reservation == null) {
        await ref
            .read(reservationViewModelProvider.notifier)
            .addReservation(reservation);
      } else {
        await ref
            .read(reservationViewModelProvider.notifier)
            .updateReservation(reservation);
      }

      if (mounted) {
        // ローディングダイアログを閉じる
        Navigator.of(context).pop();
        // 予約フォームを閉じる
        Navigator.of(context).pop();
        // 成功メッセージ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(widget.reservation == null ? '予約を作成しました' : '予約を更新しました'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // ローディングダイアログを閉じる
        Navigator.of(context).pop();

        // 重複エラーの場合
        if (e is ReservationConflictException) {
          _showConflictSnackBar(e.conflictingReservations);
        } else {
          // その他のエラー（ネットワークエラー等）
          String errorMessage = 'エラーが発生しました';

          if (e.toString().contains('network') ||
              e.toString().contains('SocketException') ||
              e.toString().contains('Failed host lookup')) {
            errorMessage = 'ネットワークエラー: インターネット接続を確認してください';
          } else if (e.toString().contains('permission-denied')) {
            errorMessage = '権限エラー: 予約の保存権限がありません';
          } else if (e.toString().contains('unavailable')) {
            errorMessage = 'サーバーエラー: Firebaseに接続できません';
          }

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('予約の保存に失敗しました'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      errorMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '詳細なエラー情報:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SelectableText(
                        e.toString(),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '対処方法:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text('• インターネット接続を確認してください'),
                    const Text('• 時間をおいて再度お試しください'),
                    const Text('• 問題が続く場合は管理者に連絡してください'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('閉じる'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _saveReservation(userId, userName);
                  },
                  child: const Text('再試行'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  /// 重複エラーをスナックバーで表示
  void _showConflictSnackBar(List<Reservation> conflicts) {
    final conflictTimes = conflicts
        .map((c) {
          return '${DateFormat('HH:mm').format(c.startTime)}-${DateFormat('HH:mm').format(c.endTime)}';
        })
        .join(', ');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '予約が重複しています',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('既に予約されている時間帯: $conflictTimes'),
            const SizedBox(height: 4),
            const Text('別の時間帯を選択してください', style: TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
      ),
    );
  }
}
