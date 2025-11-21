import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/reservation.dart';
import '../../viewmodels/equipment_viewmodel.dart';
import '../../viewmodels/reservation_viewmodel.dart';
import '../reservation_form_page.dart';

/// 予約カード
class ReservationCard extends ConsumerWidget {
  final Reservation reservation;

  const ReservationCard({super.key, required this.reservation});

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
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
