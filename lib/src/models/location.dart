/// 場所（部屋）モデル
class Location {
  final String id;
  final String name;
  final DateTime createdAt;

  Location({required this.id, required this.name, required this.createdAt});

  /// Firestoreのデータから変換
  factory Location.fromFirestore(Map<String, dynamic> data, String id) {
    return Location(
      id: id,
      name: data['name'] ?? '',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  /// Firestoreへ保存するデータに変換
  Map<String, dynamic> toFirestore() {
    return {'name': name, 'createdAt': createdAt};
  }

  Location copyWith({String? id, String? name, DateTime? createdAt}) {
    return Location(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
