import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/favorite_equipment.dart';

/// お気に入り装置リポジトリ
class FavoriteEquipmentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'favoriteEquipments';

  /// お気に入り装置のストリーム取得
  Stream<List<FavoriteEquipment>> getFavoriteEquipmentsStream(String userId) {
    debugPrint(
      '🔵 [FavoriteEquipmentRepository] getFavoriteEquipmentsStream開始: userId=$userId',
    );
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          debugPrint(
            '🔵 [FavoriteEquipmentRepository] スナップショット受信: ${snapshot.docs.length}件',
          );
          final favorites = snapshot.docs
              .map((doc) => FavoriteEquipment.fromFirestore(doc))
              .toList();
          // クライアント側でソート
          favorites.sort((a, b) => a.order.compareTo(b.order));
          debugPrint(
            '🟢 [FavoriteEquipmentRepository] お気に入りリスト返却: ${favorites.length}件',
          );
          return favorites;
        });
  }

  /// お気に入り装置の一覧取得（一度だけ）
  Future<List<FavoriteEquipment>> getFavoriteEquipments(String userId) async {
    debugPrint(
      '🔵 [FavoriteEquipmentRepository] getFavoriteEquipments開始: userId=$userId',
    );
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .get();

    debugPrint(
      '🔵 [FavoriteEquipmentRepository] 取得件数: ${snapshot.docs.length}件',
    );
    final favorites = snapshot.docs
        .map((doc) => FavoriteEquipment.fromFirestore(doc))
        .toList();
    // クライアント側でソート
    favorites.sort((a, b) => a.order.compareTo(b.order));
    debugPrint(
      '🟢 [FavoriteEquipmentRepository] お気に入りリスト返却: ${favorites.length}件',
    );
    return favorites;
  }

  /// 最大order値を取得
  Future<int> getMaxOrder(String userId) async {
    debugPrint(
      '🔵 [FavoriteEquipmentRepository] getMaxOrder開始: userId=$userId',
    );
    // インデックス不要にするため、クライアント側でソート
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .get();

    if (snapshot.docs.isEmpty) {
      debugPrint(
        '🔵 [FavoriteEquipmentRepository] getMaxOrder: お気に入りなし、order=0',
      );
      return 0;
    }

    // クライアント側で最大order値を取得
    final favorites = snapshot.docs
        .map((doc) => FavoriteEquipment.fromFirestore(doc))
        .toList();

    final maxOrder = favorites
        .map((f) => f.order)
        .reduce((a, b) => a > b ? a : b);
    debugPrint(
      '🔵 [FavoriteEquipmentRepository] getMaxOrder: maxOrder=$maxOrder (${favorites.length}件中)',
    );
    return maxOrder;
  }

  /// お気に入り装置を追加
  Future<String> addFavoriteEquipment({
    required String userId,
    required String equipmentId,
    required String equipmentName,
    required String locationId,
    required String locationName,
    required int order,
  }) async {
    debugPrint('🔵 [FavoriteEquipmentRepository] addFavoriteEquipment開始');
    debugPrint('  userId: $userId');
    debugPrint('  equipmentId: $equipmentId');
    debugPrint('  equipmentName: $equipmentName');
    debugPrint('  locationId: $locationId');
    debugPrint('  locationName: $locationName');
    debugPrint('  order: $order');

    final docRef = await _firestore.collection(_collectionName).add({
      'userId': userId,
      'equipmentId': equipmentId,
      'equipmentName': equipmentName,
      'locationId': locationId,
      'locationName': locationName,
      'order': order,
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint(
      '🟢 [FavoriteEquipmentRepository] addFavoriteEquipment完了: docId=${docRef.id}',
    );
    return docRef.id;
  }

  /// お気に入り装置を削除
  Future<void> deleteFavoriteEquipment(String favoriteEquipmentId) async {
    await _firestore
        .collection(_collectionName)
        .doc(favoriteEquipmentId)
        .delete();
  }

  /// お気に入り装置の並び順を更新
  Future<void> updateOrders(List<FavoriteEquipment> reorderedList) async {
    final batch = _firestore.batch();

    for (int i = 0; i < reorderedList.length; i++) {
      final favorite = reorderedList[i];
      final docRef = _firestore.collection(_collectionName).doc(favorite.id);
      batch.update(docRef, {'order': i});
    }

    await batch.commit();
  }

  /// 特定の装置がお気に入りに含まれているか確認
  Future<bool> isFavorite(String userId, String equipmentId) async {
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .where('equipmentId', isEqualTo: equipmentId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// 特定の装置のお気に入りIDを取得
  Future<String?> getFavoriteId(String userId, String equipmentId) async {
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .where('equipmentId', isEqualTo: equipmentId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return snapshot.docs.first.id;
  }

  /// 装置名を更新（装置情報変更時に使用）
  Future<void> updateEquipmentName(
    String equipmentId,
    String newEquipmentName,
  ) async {
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('equipmentId', isEqualTo: equipmentId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'equipmentName': newEquipmentName});
    }

    await batch.commit();
  }

  /// 場所名を更新（場所情報変更時に使用）
  Future<void> updateLocationName(
    String locationId,
    String newLocationName,
  ) async {
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('locationId', isEqualTo: locationId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'locationName': newLocationName});
    }

    await batch.commit();
  }
}
