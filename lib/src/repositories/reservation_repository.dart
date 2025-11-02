import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation.dart';

/// 予約データのリポジトリ
class ReservationRepository {
  final FirebaseFirestore _firestore;
  static const String _collectionName = 'reservations';

  ReservationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 全予約を取得（リアルタイム）
  Stream<List<Reservation>> getReservationsStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Reservation.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  /// 特定の日付の予約を取得
  Stream<List<Reservation>> getReservationsByDateStream(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _firestore
        .collection(_collectionName)
        .where('startTime', isGreaterThanOrEqualTo: startOfDay)
        .where('startTime', isLessThan: endOfDay)
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Reservation.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  /// 特定の装置の予約を取得
  Stream<List<Reservation>> getReservationsByEquipmentStream(
    String equipmentId,
  ) {
    return _firestore
        .collection(_collectionName)
        .where('equipmentId', isEqualTo: equipmentId)
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Reservation.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  /// 特定のユーザーの予約を取得
  Stream<List<Reservation>> getReservationsByUserStream(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Reservation.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  /// 予約を追加
  Future<String> addReservation(Reservation reservation) async {
    // 予約の重複チェック
    final conflicts = await _checkConflicts(
      reservation.equipmentId,
      reservation.startTime,
      reservation.endTime,
    );

    if (conflicts.isNotEmpty) {
      throw Exception('指定された時間帯は既に予約されています');
    }

    final docRef = await _firestore
        .collection(_collectionName)
        .add(reservation.toFirestore());
    return docRef.id;
  }

  /// 予約を更新
  Future<void> updateReservation(Reservation reservation) async {
    // 予約の重複チェック（自分以外）
    final conflicts = await _checkConflicts(
      reservation.equipmentId,
      reservation.startTime,
      reservation.endTime,
      excludeId: reservation.id,
    );

    if (conflicts.isNotEmpty) {
      throw Exception('指定された時間帯は既に予約されています');
    }

    await _firestore
        .collection(_collectionName)
        .doc(reservation.id)
        .update(reservation.toFirestore());
  }

  /// 予約を削除
  Future<void> deleteReservation(String id) async {
    await _firestore.collection(_collectionName).doc(id).delete();
  }

  /// 予約の重複チェック
  Future<List<Reservation>> _checkConflicts(
    String equipmentId,
    DateTime startTime,
    DateTime endTime, {
    String? excludeId,
  }) async {
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('equipmentId', isEqualTo: equipmentId)
        .where('startTime', isLessThan: endTime)
        .get();

    final reservations = snapshot.docs
        .map((doc) => Reservation.fromFirestore(doc.data(), doc.id))
        .where((r) => r.endTime.isAfter(startTime))
        .where((r) => excludeId == null || r.id != excludeId)
        .toList();

    return reservations;
  }
}
