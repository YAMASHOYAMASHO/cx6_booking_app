import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/equipment.dart';
import '../repositories/equipment_repository.dart';

/// EquipmentRepositoryのプロバイダー
final equipmentRepositoryProvider = Provider<EquipmentRepository>((ref) {
  return EquipmentRepository();
});

/// 全装置リストのプロバイダー
final equipmentsProvider = StreamProvider<List<Equipment>>((ref) {
  return ref.watch(equipmentRepositoryProvider).getEquipmentsStream();
});

/// 利用可能な装置リストのプロバイダー
final availableEquipmentsProvider = StreamProvider<List<Equipment>>((ref) {
  return ref.watch(equipmentRepositoryProvider).getAvailableEquipmentsStream();
});

/// 特定の場所の装置リストのプロバイダー
final equipmentsByLocationProvider =
    StreamProvider.family<List<Equipment>, String>((ref, locationId) {
      return ref
          .watch(equipmentRepositoryProvider)
          .getEquipmentsByLocationStream(locationId);
    });

/// 選択中の装置のプロバイダー
final selectedEquipmentProvider = StateProvider<Equipment?>((ref) => null);

/// 装置ViewModel
class EquipmentViewModel extends StateNotifier<AsyncValue<void>> {
  final EquipmentRepository _repository;

  EquipmentViewModel(this._repository) : super(const AsyncValue.data(null));

  /// 装置を追加
  Future<void> addEquipment(Equipment equipment) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.addEquipment(equipment);
    });
  }

  /// 装置を更新
  Future<void> updateEquipment(Equipment equipment) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateEquipment(equipment);
    });
  }

  /// 装置を削除
  Future<void> deleteEquipment(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteEquipment(id);
    });
  }
}

/// EquipmentViewModelのプロバイダー
final equipmentViewModelProvider =
    StateNotifierProvider<EquipmentViewModel, AsyncValue<void>>((ref) {
      return EquipmentViewModel(ref.watch(equipmentRepositoryProvider));
    });
