import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/date_range.dart';
import '../models/equipment_date_range_query.dart';
import '../models/reservation.dart';
import 'auth_viewmodel.dart';
import 'reservation_viewmodel.dart';

/// 選択された装置のプロバイダー
final selectedEquipmentProvider = StateProvider<String?>((ref) => null);

/// 日付範囲のプロバイダー（デフォルト: 今日から3週間）
final dateRangeProvider = StateProvider<DateRange>((ref) {
  final today = DateTime.now();
  final startOfToday = DateTime(today.year, today.month, today.day);
  return DateRange(
    start: startOfToday,
    end: startOfToday.add(const Duration(days: 20)), // 21日間（0日目～20日目）
  );
});

/// 装置別・期間内予約リストのプロバイダー
final reservationsByEquipmentAndDateRangeProvider =
    StreamProvider.family<List<Reservation>, EquipmentDateRangeQuery>((
      ref,
      query,
    ) {
      // 認証状態を確認
      final authUser = ref.watch(authStateProvider).value;

      // 認証されていない場合は空リストを返す
      if (authUser == null) {
        return Stream.value([]);
      }

      return ref
          .watch(reservationRepositoryProvider)
          .getReservationsByEquipmentAndDateRange(
            query.equipmentId,
            query.startDate,
            query.endDate,
          );
    });

/// 選択された装置と日付範囲に基づく予約のプロバイダー
final selectedEquipmentReservationsProvider = StreamProvider<List<Reservation>>(
  (ref) {
    // 認証状態を確認
    final authUser = ref.watch(authStateProvider).value;
    if (authUser == null) {
      return Stream.value([]);
    }

    final equipmentId = ref.watch(selectedEquipmentProvider);
    final dateRange = ref.watch(dateRangeProvider);

    // 装置が選択されていない場合は空リストを返す
    if (equipmentId == null || equipmentId.isEmpty) {
      return Stream.value([]);
    }

    final query = EquipmentDateRangeQuery(
      equipmentId: equipmentId,
      startDate: dateRange.start,
      endDate: dateRange.end,
    );

    return ref.watch(reservationsByEquipmentAndDateRangeProvider(query).stream);
  },
);
