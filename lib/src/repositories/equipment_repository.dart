import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/equipment.dart';

/// 装置データのリポジトリ
class EquipmentRepository {
  final FirebaseFirestore _firestore;
  static const String _collectionName = 'equipments';

  EquipmentRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 全装置を取得（リアルタイム）
  Stream<List<Equipment>> getEquipmentsStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Equipment.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  /// 特定の装置を取得
  Future<Equipment?> getEquipmentById(String id) async {
    final doc = await _firestore.collection(_collectionName).doc(id).get();
    if (doc.exists && doc.data() != null) {
      return Equipment.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  /// 装置を追加（管理者用）
  Future<String> addEquipment(Equipment equipment) async {
    final docRef = await _firestore
        .collection(_collectionName)
        .add(equipment.toFirestore());
    return docRef.id;
  }

  /// 装置を更新（管理者用）
  Future<void> updateEquipment(Equipment equipment) async {
    await _firestore
        .collection(_collectionName)
        .doc(equipment.id)
        .update(equipment.toFirestore());
  }

  /// 装置を削除（管理者用）
  Future<void> deleteEquipment(String id) async {
    await _firestore.collection(_collectionName).doc(id).delete();
  }

  /// 利用可能な装置のみを取得
  Stream<List<Equipment>> getAvailableEquipmentsStream() {
    return _firestore
        .collection(_collectionName)
        .where('status', isEqualTo: 'available')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Equipment.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  /// 特定の場所の装置を取得
  Stream<List<Equipment>> getEquipmentsByLocationStream(String locationId) {
    return _firestore
        .collection(_collectionName)
        .where('location', isEqualTo: locationId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Equipment.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }
}
