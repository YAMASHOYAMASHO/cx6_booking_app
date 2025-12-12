import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reservation.dart';
import '../repositories/reservation_repository.dart';
import '../services/reservation_cache_service.dart';
import 'auth_viewmodel.dart';
import 'cache_viewmodel.dart';

/// ReservationRepositoryのプロバイダー
final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  return ReservationRepository();
});

/// 全予約リストのプロバイダー（管理者用：全件取得するため注意）
final adminAllReservationsProvider = StreamProvider<List<Reservation>>((ref) {
  // 認証状態を確認
  final authUser = ref.watch(authStateProvider).value;

  // 認証されていない場合は空リストを返す
  if (authUser == null) {
    return Stream.value([]);
  }

  return ref.watch(reservationRepositoryProvider).getReservationsStream();
});

/// 選択された日付のプロバイダー
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

/// 選択された日付の予約リストのプロバイダー（認証状態を確認）
final reservationsByDateProvider = StreamProvider<List<Reservation>>((ref) {
  // 認証状態を確認
  final authUser = ref.watch(authStateProvider).value;

  // 認証されていない場合は空リストを返す
  if (authUser == null) {
    return Stream.value([]);
  }

  final date = ref.watch(selectedDateProvider);
  return ref
      .watch(reservationRepositoryProvider)
      .getReservationsByDateStream(date);
});

/// 特定の装置の予約リストのプロバイダー（認証状態を確認）
final reservationsByEquipmentProvider =
    StreamProvider.family<List<Reservation>, String>((ref, equipmentId) {
      // 認証状態を確認
      final authUser = ref.watch(authStateProvider).value;

      // 認証されていない場合は空リストを返す
      if (authUser == null) {
        return Stream.value([]);
      }

      return ref
          .watch(reservationRepositoryProvider)
          .getReservationsByEquipmentStream(equipmentId);
    });

/// 特定のユーザーの予約リストのプロバイダー（認証状態を確認）
final reservationsByUserProvider =
    StreamProvider.family<List<Reservation>, String>((ref, userId) {
      // 認証状態を確認
      final authUser = ref.watch(authStateProvider).value;

      // 認証されていない場合は空リストを返す
      if (authUser == null) {
        return Stream.value([]);
      }

      return ref
          .watch(reservationRepositoryProvider)
          .getReservationsByUserStream(userId);
    });

/// 予約ViewModel
///
/// 予約のCRUD操作を担当。
/// 重要: 予約の追加/更新/削除時には、関連するキャッシュを自動的に無効化する。
/// 重複チェック（_checkConflicts）は常にFirestoreから直接取得するため、
/// キャッシュによる重複問題は発生しない。
class ReservationViewModel extends StateNotifier<AsyncValue<void>> {
  final ReservationRepository _repository;
  final ReservationCacheService _cacheService;

  ReservationViewModel(this._repository, this._cacheService)
    : super(const AsyncValue.data(null));

  /// 予約を追加
  Future<void> addReservation(Reservation reservation) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addReservation(reservation);

      // キャッシュを無効化
      _invalidateRelatedCache(reservation);

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow; // 例外を再スローしてUIで捕捉できるようにする
    }
  }

  /// 予約を更新
  Future<void> updateReservation(Reservation reservation) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateReservation(reservation);

      // キャッシュを無効化
      _invalidateRelatedCache(reservation);

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow; // 例外を再スローしてUIで捕捉できるようにする
    }
  }

  /// 予約を削除
  Future<void> deleteReservation(String id, {Reservation? reservation}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteReservation(id);

      // キャッシュを無効化（予約情報があれば詳細に無効化）
      if (reservation != null) {
        _invalidateRelatedCache(reservation);
      } else {
        // 予約情報がない場合は全キャッシュをクリア
        _cacheService.invalidateAll();
      }

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow; // 例外を再スローしてUIで捕捉できるようにする
    }
  }

  /// 関連するキャッシュを無効化
  void _invalidateRelatedCache(Reservation reservation) {
    // 装置に関連するキャッシュを無効化
    _cacheService.invalidateByEquipment(reservation.equipmentId);

    // ユーザーのキャッシュを無効化
    _cacheService.invalidateByUser(reservation.userId);
  }
}

/// ReservationViewModelのプロバイダー
final reservationViewModelProvider =
    StateNotifierProvider<ReservationViewModel, AsyncValue<void>>((ref) {
      return ReservationViewModel(
        ref.watch(reservationRepositoryProvider),
        ref.watch(reservationCacheServiceProvider),
      );
    });
