import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/date_range.dart';
import '../models/equipment_date_range_query.dart';
import '../models/reservation.dart';
import 'auth_viewmodel.dart';
import 'reservation_viewmodel.dart';
import 'cache_viewmodel.dart';

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

/// 装置別・期間内予約リストのプロバイダー（キャッシュ対応版）
///
/// 1. まずローカルキャッシュを確認
/// 2. キャッシュがあればそれを返す
/// 3. キャッシュがなければFirestoreから取得してキャッシュに保存
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

      final cacheService = ref.read(reservationCacheServiceProvider);

      // キャッシュを確認
      final cached = cacheService.getByEquipmentAndDateRange(
        query.equipmentId,
        query.startDate,
        query.endDate,
      );

      if (cached != null) {
        // キャッシュヒット: キャッシュデータを返しつつ、バックグラウンドで更新
        return _createCachedStream(ref, query, cached, cacheService);
      }

      // キャッシュミス: Firestoreから取得
      return ref
          .watch(reservationRepositoryProvider)
          .getReservationsByEquipmentAndDateRange(
            query.equipmentId,
            query.startDate,
            query.endDate,
          )
          .map((reservations) {
            // キャッシュに保存
            cacheService.setByEquipmentAndDateRange(
              query.equipmentId,
              query.startDate,
              query.endDate,
              reservations,
            );
            return reservations;
          });
    });

/// キャッシュヒット時のストリーム生成
/// 最初にキャッシュデータを返し、その後Firestoreからの更新を流す
Stream<List<Reservation>> _createCachedStream(
  Ref ref,
  EquipmentDateRangeQuery query,
  List<Reservation> cachedData,
  dynamic cacheService,
) async* {
  // 最初にキャッシュデータを返す
  yield cachedData;

  // バックグラウンドでFirestoreからの更新を監視
  await for (final reservations
      in ref
          .watch(reservationRepositoryProvider)
          .getReservationsByEquipmentAndDateRange(
            query.equipmentId,
            query.startDate,
            query.endDate,
          )) {
    // キャッシュを更新
    cacheService.setByEquipmentAndDateRange(
      query.equipmentId,
      query.startDate,
      query.endDate,
      reservations,
    );
    yield reservations;
  }
}

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
