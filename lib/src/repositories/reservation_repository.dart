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

  /// 特定のユーザーの予約を取得（今日以降の予約、最新10件）
  Stream<List<Reservation>> getReservationsByUserStream(String userId) {
    // 今日の0時0分を取得
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .where('startTime', isGreaterThanOrEqualTo: todayStart)
        .orderBy('startTime')
        .limit(10) // 読み取り数削減のため制限
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Reservation.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  /// 特定の装置の期間内予約を取得（装置別タイムライン用）
  Stream<List<Reservation>> getReservationsByEquipmentAndDateRange(
    String equipmentId,
    DateTime startDate,
    DateTime endDate,
  ) {
    final startOfFirstDay = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      0,
      0,
      0,
    );
    final endOfLastDay = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
    );

    return _firestore
        .collection(_collectionName)
        .where('equipmentId', isEqualTo: equipmentId)
        .where('startTime', isGreaterThanOrEqualTo: startOfFirstDay)
        .where('startTime', isLessThanOrEqualTo: endOfLastDay)
        .orderBy('startTime')
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

  /// 予約の重複チェック（最適化版）
  Future<List<Reservation>> _checkConflicts(
    String equipmentId,
    DateTime startTime,
    DateTime endTime, {
    String? excludeId,
  }) async {
    // 最適化されたクエリ:
    // 既存予約の終了時刻が、新規予約の開始時刻より後であるものだけを取得する。
    // これにより、既に終わっている過去の予約を全て除外できる。
    // Note: これには複合インデックス (equipmentId ASC, endTime ASC) が必要になる場合がある。

    final snapshot = await _firestore
        .collection(_collectionName)
        .where('equipmentId', isEqualTo: equipmentId)
        .where('endTime', isGreaterThan: startTime) // 終了時刻が開始時刻より未来のものだけ
        .get();

    print(
      '重複チェック開始(最適化済): equipmentId=$equipmentId, 開始=${startTime.toString()}, 終了=${endTime.toString()}',
    );
    print('取得した候補予約数: ${snapshot.docs.length}');

    // メモリ内で厳密なチェック
    // 重複条件: (新規予約の開始時刻 < 既存予約の終了時刻) AND (新規予約の終了時刻 > 既存予約の開始時刻)
    // クエリで `endTime > startTime` は保証されているので、
    // 残りの条件 `startTime < endTime` (既存予約の開始 < 新規予約の終了) をチェックすればよい。
    final conflicts = snapshot.docs
        .map((doc) => Reservation.fromFirestore(doc.data(), doc.id))
        .where((r) {
          // 自分自身は除外
          if (excludeId != null && r.id == excludeId) {
            return false;
          }

          // 既にクエリで r.endTime > startTime はフィルタされているため、
          // ここでは r.startTime < endTime だけチェックすれば重複確定
          final hasConflict = r.startTime.isBefore(endTime);

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
