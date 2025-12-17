import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/favorite_reservation_template.dart';
import '../models/favorite_reservation_execution.dart';
import '../models/reservation_slot.dart';
import '../models/reservation.dart';

/// お気に入り予約テンプレートリポジトリ
class FavoriteReservationTemplateRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'favoriteReservationTemplates';

  /// テンプレートのストリーム取得
  Stream<List<FavoriteReservationTemplate>> getTemplatesStream(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final templates = snapshot.docs
              .map((doc) => FavoriteReservationTemplate.fromFirestore(doc))
              .toList();

          // クライアント側でソート（インデックス不要）
          templates.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return templates;
        });
  }

  /// テンプレートの一覧取得
  Future<List<FavoriteReservationTemplate>> getTemplates(String userId) async {
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .get();

    final templates = snapshot.docs
        .map((doc) => FavoriteReservationTemplate.fromFirestore(doc))
        .toList();

    // クライアント側でソート（インデックス不要）
    templates.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return templates;
  }

  /// 特定のテンプレート取得
  Future<FavoriteReservationTemplate?> getTemplate(String templateId) async {
    final doc = await _firestore
        .collection(_collectionName)
        .doc(templateId)
        .get();

    if (!doc.exists) {
      return null;
    }

    return FavoriteReservationTemplate.fromFirestore(doc);
  }

  /// テンプレート作成
  Future<String> createTemplate({
    required String userId,
    required String name,
    String? description,
    required List<ReservationSlot> slots,
  }) async {
    final now = DateTime.now();
    final docRef = await _firestore.collection(_collectionName).add({
      'userId': userId,
      'name': name,
      'description': description,
      'slots': slots.map((slot) => slot.toJson()).toList(),
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    return docRef.id;
  }

  /// テンプレート更新
  Future<void> updateTemplate({
    required String templateId,
    String? name,
    String? description,
    List<ReservationSlot>? slots,
  }) async {
    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) {
      updateData['name'] = name;
    }
    if (description != null) {
      updateData['description'] = description;
    }
    if (slots != null) {
      updateData['slots'] = slots.map((slot) => slot.toJson()).toList();
    }

    await _firestore
        .collection(_collectionName)
        .doc(templateId)
        .update(updateData);
  }

  /// テンプレート削除
  Future<void> deleteTemplate(String templateId) async {
    await _firestore.collection(_collectionName).doc(templateId).delete();
  }

  /// 競合チェック
  Future<List<ConflictInfo>> checkConflicts(
    String templateId,
    DateTime baseDate,
  ) async {
    // テンプレート取得
    final template = await getTemplate(templateId);
    if (template == null) {
      throw Exception('テンプレートが見つかりません');
    }

    final conflicts = <ConflictInfo>[];

    // 各スロットについて既存予約との競合をチェック
    for (final slot in template.slots) {
      final startTime = slot.getStartDateTime(baseDate);
      final endTime = slot.getEndDateTime(baseDate);

      // 既存予約を検索（同じ装置、時間が重複）
      final existingReservations = await _firestore
          .collection('reservations')
          .where('equipmentId', isEqualTo: slot.equipmentId)
          .where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startTime),
          )
          .where('startTime', isLessThan: Timestamp.fromDate(endTime))
          .get();

      // 厳密な重複チェック
      for (final doc in existingReservations.docs) {
        final existingReservation = Reservation.fromFirestore(
          doc.data(),
          doc.id,
        );

        // 時間が重複しているかチェック
        if (_isOverlapping(
          startTime,
          endTime,
          existingReservation.startTime,
          existingReservation.endTime,
        )) {
          conflicts.add(
            ConflictInfo(slot: slot, existingReservation: existingReservation),
          );
        }
      }
    }

    return conflicts;
  }

  /// 時間の重複チェック
  bool _isOverlapping(
    DateTime start1,
    DateTime end1,
    DateTime start2,
    DateTime end2,
  ) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  /// 装置名を更新（装置情報変更時に使用）
  Future<void> updateEquipmentNameInSlots(
    String equipmentId,
    String newEquipmentName,
  ) async {
    final snapshot = await _firestore
        .collection(_collectionName)
        .where('slots', arrayContains: {'equipmentId': equipmentId})
        .get();

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      final template = FavoriteReservationTemplate.fromFirestore(doc);
      final updatedSlots = template.slots.map((slot) {
        if (slot.equipmentId == equipmentId) {
          return slot.copyWith(equipmentName: newEquipmentName);
        }
        return slot;
      }).toList();

      batch.update(doc.reference, {
        'slots': updatedSlots.map((slot) => slot.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// ユーザーの全テンプレートを削除（アカウント削除時に使用）
  Future<void> deleteAllByUser(String userId) async {
    debugPrint('🗑️ [FavoriteTemplateRepo] deleteAllByUser 開始: userId=$userId');

    final snapshot = await _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .get();

    debugPrint('🗑️ [FavoriteTemplateRepo] 削除対象数: ${snapshot.docs.length}');

    if (snapshot.docs.isEmpty) {
      debugPrint('✅ [FavoriteTemplateRepo] 削除対象のテンプレートなし');
      return;
    }

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    debugPrint('✅ [FavoriteTemplateRepo] deleteAllByUser 成功');
  }
}
