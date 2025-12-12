import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reservation.dart';
import '../repositories/reservation_repository.dart';
import 'auth_viewmodel.dart';

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
class ReservationViewModel extends StateNotifier<AsyncValue<void>> {
  final ReservationRepository _repository;

  ReservationViewModel(this._repository) : super(const AsyncValue.data(null));

  /// 予約を追加
  Future<void> addReservation(Reservation reservation) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addReservation(reservation);
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
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow; // 例外を再スローしてUIで捕捉できるようにする
    }
  }

  /// 予約を削除
  Future<void> deleteReservation(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteReservation(id);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow; // 例外を再スローしてUIで捕捉できるようにする
    }
  }
}

/// ReservationViewModelのプロバイダー
final reservationViewModelProvider =
    StateNotifierProvider<ReservationViewModel, AsyncValue<void>>((ref) {
      return ReservationViewModel(ref.watch(reservationRepositoryProvider));
    });
