import 'package:cloud_firestore/cloud_firestore.dart';

/// お気に入り装置モデル
class FavoriteEquipment {
  final String id; // ドキュメントID
  final String userId; // ユーザーID
  final String equipmentId; // 装置ID
  final String equipmentName; // 装置名（キャッシュ）
  final String locationId; // 場所ID（キャッシュ）
  final String locationName; // 場所名（キャッシュ）
  final int order; // 表示順序
  final DateTime createdAt; // 登録日時

  FavoriteEquipment({
    required this.id,
    required this.userId,
    required this.equipmentId,
    required this.equipmentName,
    required this.locationId,
    required this.locationName,
    this.order = 0,
    required this.createdAt,
  });

  /// Firestoreドキュメントから変換
  factory FavoriteEquipment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FavoriteEquipment(
      id: doc.id,
      userId: data['userId'] as String,
      equipmentId: data['equipmentId'] as String,
      equipmentName: data['equipmentName'] as String,
      locationId: data['locationId'] as String,
      locationName: data['locationName'] as String,
      order: data['order'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Firestoreドキュメントに変換
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'equipmentId': equipmentId,
      'equipmentName': equipmentName,
      'locationId': locationId,
      'locationName': locationName,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// 並び替え用コピー
  FavoriteEquipment copyWith({
    String? id,
    String? userId,
    String? equipmentId,
    String? equipmentName,
    String? locationId,
    String? locationName,
    int? order,
    DateTime? createdAt,
  }) {
    return FavoriteEquipment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      equipmentId: equipmentId ?? this.equipmentId,
      equipmentName: equipmentName ?? this.equipmentName,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'FavoriteEquipment(id: $id, equipmentName: $equipmentName, order: $order)';
  }
}
