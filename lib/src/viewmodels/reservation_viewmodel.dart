import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reservation.dart';
import '../repositories/reservation_repository.dart';

/// ReservationRepositoryのプロバイダー
final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  return ReservationRepository();
});

/// 全予約リストのプロバイダー
final reservationsProvider = StreamProvider<List<Reservation>>((ref) {
  return ref.watch(reservationRepositoryProvider).getReservationsStream();
});

/// 選択された日付のプロバイダー
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

/// 選択された日付の予約リストのプロバイダー
final reservationsByDateProvider = StreamProvider<List<Reservation>>((ref) {
  final date = ref.watch(selectedDateProvider);
  return ref
      .watch(reservationRepositoryProvider)
      .getReservationsByDateStream(date);
});

/// 特定の装置の予約リストのプロバイダー
final reservationsByEquipmentProvider =
    StreamProvider.family<List<Reservation>, String>((ref, equipmentId) {
      return ref
          .watch(reservationRepositoryProvider)
          .getReservationsByEquipmentStream(equipmentId);
    });

/// 特定のユーザーの予約リストのプロバイダー
final reservationsByUserProvider =
    StreamProvider.family<List<Reservation>, String>((ref, userId) {
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
    state = await AsyncValue.guard(() async {
      await _repository.addReservation(reservation);
    });
  }

  /// 予約を更新
  Future<void> updateReservation(Reservation reservation) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateReservation(reservation);
    });
  }

  /// 予約を削除
  Future<void> deleteReservation(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteReservation(id);
    });
  }
}

/// ReservationViewModelのプロバイダー
final reservationViewModelProvider =
    StateNotifierProvider<ReservationViewModel, AsyncValue<void>>((ref) {
      return ReservationViewModel(ref.watch(reservationRepositoryProvider));
    });
