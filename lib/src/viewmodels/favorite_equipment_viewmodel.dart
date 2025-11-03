import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/favorite_equipment.dart';
import '../models/equipment.dart';
import '../repositories/favorite_equipment_repository.dart';
import 'auth_viewmodel.dart';
import 'equipment_viewmodel.dart';

/// FavoriteEquipmentRepositoryのプロバイダー
final favoriteEquipmentRepositoryProvider =
    Provider<FavoriteEquipmentRepository>((ref) {
      return FavoriteEquipmentRepository();
    });

/// お気に入り装置リストのプロバイダー
final favoriteEquipmentsProvider = StreamProvider<List<FavoriteEquipment>>((
  ref,
) {
  final user = ref.watch(currentUserProvider).value;
  print('🔵 [favoriteEquipmentsProvider] user: ${user?.id ?? "null"}');
  if (user == null) return Stream.value([]);

  final stream = ref
      .watch(favoriteEquipmentRepositoryProvider)
      .getFavoriteEquipmentsStream(user.id);

  // ストリームの内容をログ出力
  return stream.map((favorites) {
    print('🟢 [favoriteEquipmentsProvider] お気に入り受信: ${favorites.length}件');
    for (var fav in favorites) {
      print('  - ${fav.equipmentName} (order: ${fav.order})');
    }
    return favorites;
  });
});

/// お気に入り装置の詳細情報（Equipment情報を含む）
class FavoriteEquipmentDetail {
  final FavoriteEquipment favorite;
  final Equipment? equipment; // 装置が削除されている場合はnull

  FavoriteEquipmentDetail({required this.favorite, this.equipment});

  bool get isAvailable => equipment?.isAvailable ?? false;
}

/// お気に入り装置の詳細リスト（装置情報と結合）
final favoriteEquipmentDetailsProvider =
    FutureProvider<List<FavoriteEquipmentDetail>>((ref) async {
      final favoritesAsync = ref.watch(favoriteEquipmentsProvider);
      final equipmentsAsync = ref.watch(equipmentsProvider);

      final favorites = await favoritesAsync.when(
        data: (data) async => data,
        loading: () async => <FavoriteEquipment>[],
        error: (_, __) async => <FavoriteEquipment>[],
      );

      final equipments = await equipmentsAsync.when(
        data: (data) async => data,
        loading: () async => <Equipment>[],
        error: (_, __) async => <Equipment>[],
      );

      final details = favorites.map((favorite) {
        final equipment = equipments.cast<Equipment?>().firstWhere(
          (e) => e?.id == favorite.equipmentId,
          orElse: () => null,
        );

        return FavoriteEquipmentDetail(
          favorite: favorite,
          equipment: equipment,
        );
      }).toList();

      return details;
    });

/// 特定の装置がお気に入りかどうかを判定
final isFavoriteEquipmentProvider = Provider.family<bool, String>((
  ref,
  equipmentId,
) {
  final favorites = ref.watch(favoriteEquipmentsProvider).value ?? [];
  return favorites.any((f) => f.equipmentId == equipmentId);
});

/// お気に入り装置ViewModel
class FavoriteEquipmentViewModel extends StateNotifier<AsyncValue<void>> {
  final FavoriteEquipmentRepository _repository;
  final String _userId;

  FavoriteEquipmentViewModel(this._repository, this._userId)
    : super(const AsyncValue.data(null));

  /// お気に入りに追加
  Future<void> addFavorite(Equipment equipment) async {
    print(
      '🔵 [FavoriteEquipmentViewModel] addFavorite開始: ${equipment.name} (${equipment.id})',
    );
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      print('🔵 [FavoriteEquipmentViewModel] userId: $_userId');

      // 既にお気に入りに登録されているかチェック
      final isFavorite = await _repository.isFavorite(_userId, equipment.id);
      print('🔵 [FavoriteEquipmentViewModel] isFavorite: $isFavorite');
      if (isFavorite) {
        throw Exception('この装置は既にお気に入りに登録されています');
      }

      // location名を取得するために、Firestoreから直接取得
      final firestore = FirebaseFirestore.instance;
      print(
        '🔵 [FavoriteEquipmentViewModel] location取得開始: ${equipment.locationId}',
      );
      final locationDoc = await firestore
          .collection('locations')
          .doc(equipment.locationId)
          .get();
      final locationName = locationDoc.data()?['name'] as String? ?? '不明な場所';
      print('🔵 [FavoriteEquipmentViewModel] locationName: $locationName');

      // 最大order値を取得して+1
      final maxOrder = await _repository.getMaxOrder(_userId);
      print('🔵 [FavoriteEquipmentViewModel] maxOrder: $maxOrder');

      print('🔵 [FavoriteEquipmentViewModel] お気に入り追加開始');
      await _repository.addFavoriteEquipment(
        userId: _userId,
        equipmentId: equipment.id,
        equipmentName: equipment.name,
        locationId: equipment.locationId,
        locationName: locationName,
        order: maxOrder + 1,
      );
      print('🔵 [FavoriteEquipmentViewModel] お気に入り追加完了');
    });

    if (state.hasError) {
      print('🔴 [FavoriteEquipmentViewModel] エラー発生: ${state.error}');
    } else {
      print('🟢 [FavoriteEquipmentViewModel] addFavorite完了');
    }
  }

  /// お気に入りから削除
  Future<void> removeFavorite(String favoriteEquipmentId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteFavoriteEquipment(favoriteEquipmentId);
    });
  }

  /// 装置IDでお気に入りから削除
  Future<void> removeFavoriteByEquipmentId(String equipmentId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final favoriteId = await _repository.getFavoriteId(_userId, equipmentId);
      if (favoriteId != null) {
        await _repository.deleteFavoriteEquipment(favoriteId);
      }
    });
  }

  /// お気に入りの並び替え
  Future<void> reorder(List<FavoriteEquipment> reorderedList) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // 新しいorder値を設定
      final updatedList = <FavoriteEquipment>[];
      for (int i = 0; i < reorderedList.length; i++) {
        updatedList.add(reorderedList[i].copyWith(order: i));
      }
      await _repository.updateOrders(updatedList);
    });
  }

  /// お気に入りトグル（追加/削除を切り替え）
  Future<void> toggleFavorite(Equipment equipment) async {
    final isFavorite = await _repository.isFavorite(_userId, equipment.id);
    if (isFavorite) {
      await removeFavoriteByEquipmentId(equipment.id);
    } else {
      await addFavorite(equipment);
    }
  }
}

/// FavoriteEquipmentViewModelのプロバイダー
final favoriteEquipmentViewModelProvider =
    StateNotifierProvider<FavoriteEquipmentViewModel, AsyncValue<void>>((ref) {
      final user = ref.watch(currentUserProvider).value;
      return FavoriteEquipmentViewModel(
        ref.watch(favoriteEquipmentRepositoryProvider),
        user?.id ?? '',
      );
    });
