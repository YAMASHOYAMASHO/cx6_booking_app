import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/location.dart';
import '../repositories/location_repository.dart';
import 'auth_viewmodel.dart';

/// LocationRepositoryのプロバイダー
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository();
});

/// 全場所リストのプロバイダー（認証状態を確認）
final locationsProvider = StreamProvider<List<Location>>((ref) {
  // 認証状態を確認
  final authUser = ref.watch(authStateProvider).value;

  // 認証されていない場合は選択をクリアして空リストを返す
  if (authUser == null) {
    // 選択状態をリセット
    Future.microtask(() {
      ref.read(selectedLocationProvider.notifier).state = null;
    });
    return Stream.value([]);
  }

  return ref.watch(locationRepositoryProvider).getLocationsStream();
});

/// 選択中の場所のプロバイダー
final selectedLocationProvider = StateProvider<Location?>((ref) => null);

/// 選択中の場所ID（String?型、管理画面用）
final selectedLocationIdProvider = StateProvider<String?>((ref) => null);

/// 場所ViewModel
class LocationViewModel extends StateNotifier<AsyncValue<void>> {
  final LocationRepository _repository;

  LocationViewModel(this._repository) : super(const AsyncValue.data(null));

  /// 場所を追加
  Future<void> addLocation(Location location) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.addLocation(location);
    });
  }

  /// 場所を更新
  Future<void> updateLocation(Location location) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateLocation(location);
    });
  }

  /// 場所を削除
  Future<void> deleteLocation(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteLocation(id);
    });
  }
}

/// LocationViewModelのプロバイダー
final locationViewModelProvider =
    StateNotifierProvider<LocationViewModel, AsyncValue<void>>((ref) {
      return LocationViewModel(ref.watch(locationRepositoryProvider));
    });
