import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation.dart';

/// 予約の重複エラー
class ReservationConflictException implements Exception {
  final String message;
  final List<Reservation> conflictingReservations;

  ReservationConflictException(this.message, this.conflictingReservations);

  @override
  String toString() => message;
}

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
      throw ReservationConflictException('指定された時間帯は既に予約されています', conflicts);
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
      throw ReservationConflictException('指定された時間帯は既に予約されています', conflicts);
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
    // 同じ装置の予約を全て取得
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('equipmentId', isEqualTo: equipmentId)
        .get();

    print(
      '重複チェック開始: equipmentId=$equipmentId, 開始=${startTime.toString()}, 終了=${endTime.toString()}',
    );
    print('取得した予約数: ${snapshot.docs.length}');

    // 時間の重複をチェック
    // 重複条件: (新規予約の開始時刻 < 既存予約の終了時刻) AND (新規予約の終了時刻 > 既存予約の開始時刻)
    final conflicts = snapshot.docs
        .map((doc) => Reservation.fromFirestore(doc.data(), doc.id))
        .where((r) {
          // 自分自身は除外
          if (excludeId != null && r.id == excludeId) {
            return false;
          }
          // 時間の重複チェック
          final hasConflict =
              startTime.isBefore(r.endTime) && endTime.isAfter(r.startTime);
          if (hasConflict) {
            print('重複発見: ${r.id}, 開始=${r.startTime}, 終了=${r.endTime}');
          }
          return hasConflict;
        })
        .toList();

    print('重複予約数: ${conflicts.length}');
    return conflicts;
  }
}
