import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/location.dart';
import '../../../viewmodels/reservation_viewmodel.dart';
import '../../../viewmodels/equipment_viewmodel.dart';
import '../../widgets/common/error_display.dart';
import 'horizontal_timeline_grid.dart';

/// タイムライン表示（横方向）
class TimelineView extends ConsumerWidget {
  final Location location;
  final DateTime selectedDate;

  const TimelineView({
    super.key,
    required this.location,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipmentsAsync = ref.watch(
      equipmentsByLocationProvider(location.id),
    );
    final reservationsAsync = ref.watch(reservationsByDateProvider);
    final dateFormat = DateFormat('M月d日(E)', 'ja_JP');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日付表示ヘッダー
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.calendar_today),
              const SizedBox(width: 8),
              Text(
                dateFormat.format(selectedDate),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              const Text(
                'タイムラインをクリックして予約',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // タイムライン
        Expanded(
          child: equipmentsAsync.when(
            data: (equipments) {
              if (equipments.isEmpty) {
                return const Center(child: Text('この部屋には装置がありません'));
              }
              return reservationsAsync.when(
                data: (allReservations) {
                  return HorizontalTimelineGrid(
                    equipments: equipments,
                    reservations: allReservations,
                    selectedDate: selectedDate,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    Center(child: ErrorDisplay(error: error)),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: ErrorDisplay(error: error)),
          ),
        ),
      ],
    );
  }
}
