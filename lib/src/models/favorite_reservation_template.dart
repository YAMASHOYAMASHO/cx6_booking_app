import 'package:cloud_firestore/cloud_firestore.dart';
import 'reservation_slot.dart';

/// お気に入り予約テンプレート
class FavoriteReservationTemplate {
  final String id; // ドキュメントID
  final String userId; // ユーザーID
  final String name; // テンプレート名（例: "月曜日の実験セット"）
  final String? description; // 説明
  final List<ReservationSlot> slots; // 予約スロットリスト
  final DateTime createdAt; // 作成日時
  final DateTime updatedAt; // 更新日時

  FavoriteReservationTemplate({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.slots,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firestoreドキュメントから変換
  factory FavoriteReservationTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final slotsData = data['slots'] as List<dynamic>? ?? [];

    return FavoriteReservationTemplate(
      id: doc.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      description: data['description'] as String?,
      slots: slotsData
          .map(
            (slotData) =>
                ReservationSlot.fromJson(slotData as Map<String, dynamic>),
          )
          .toList(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Firestoreドキュメントに変換
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'slots': slots.map((slot) => slot.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// コピー
  FavoriteReservationTemplate copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    List<ReservationSlot>? slots,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FavoriteReservationTemplate(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      slots: slots ?? this.slots,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// スロット数
  int get slotCount => slots.length;

  /// 予約される装置の一覧（重複なし）
  Set<String> get uniqueEquipmentIds =>
      slots.map((slot) => slot.equipmentId).toSet();

  /// 予約される日数の範囲
  int get dayRange {
    if (slots.isEmpty) return 0;
    final offsets = slots.map((slot) => slot.dayOffset).toList();
    return offsets.reduce((a, b) => a > b ? a : b) -
        offsets.reduce((a, b) => a < b ? a : b) +
        1;
  }

  @override
  String toString() {
    return 'FavoriteReservationTemplate(id: $id, name: $name, slots: ${slots.length})';
  }
}
