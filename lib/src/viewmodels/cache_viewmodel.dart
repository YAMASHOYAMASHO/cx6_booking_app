import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/reservation_cache_service.dart';

/// ReservationCacheServiceのプロバイダー（シングルトン）
final reservationCacheServiceProvider = Provider<ReservationCacheService>((
  ref,
) {
  return ReservationCacheService();
});

/// キャッシュ統計情報プロバイダー（デバッグ用）
final cacheStatsProvider = Provider<Map<String, dynamic>>((ref) {
  return ref.watch(reservationCacheServiceProvider).stats;
});
