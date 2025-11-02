import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/location.dart';

/// 場所（部屋）データのリポジトリ
class LocationRepository {
  final FirebaseFirestore _firestore;
  static const String _collectionName = 'locations';

  LocationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 全場所を取得（リアルタイム）
  Stream<List<Location>> getLocationsStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Location.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  /// 特定の場所を取得
  Future<Location?> getLocationById(String id) async {
    final doc = await _firestore.collection(_collectionName).doc(id).get();
    if (doc.exists && doc.data() != null) {
      return Location.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  /// 場所を追加（管理者用）
  Future<String> addLocation(Location location) async {
    final docRef = await _firestore
        .collection(_collectionName)
        .add(location.toFirestore());
    return docRef.id;
  }

  /// 場所を更新（管理者用）
  Future<void> updateLocation(Location location) async {
    await _firestore
        .collection(_collectionName)
        .doc(location.id)
        .update(location.toFirestore());
  }

  /// 場所を削除（管理者用）
  Future<void> deleteLocation(String id) async {
    await _firestore.collection(_collectionName).doc(id).delete();
  }
}
