/// 装置モデル
class Equipment {
  final String id;
  final String name;
  final String description;
  final String locationId;
  final String? imageUrl;
  final String? specifications;
  final String status; // 'available', 'unavailable', etc.
  final DateTime createdAt;

  Equipment({
    required this.id,
    required this.name,
    required this.description,
    required this.locationId,
    this.imageUrl,
    this.specifications,
    this.status = 'available',
    required this.createdAt,
  });

  /// 装置が利用可能か
  bool get isAvailable => status == 'available';

  /// Firestoreのデータから変換
  factory Equipment.fromFirestore(Map<String, dynamic> data, String id) {
    return Equipment(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      locationId: data['location'] ?? '',
      imageUrl: data['imageUrl'],
      specifications: data['specifications'],
      status: data['status'] ?? 'available',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  /// Firestoreへ保存するデータに変換
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'location': locationId,
      'imageUrl': imageUrl,
      'specifications': specifications,
      'status': status,
      'createdAt': createdAt,
    };
  }

  Equipment copyWith({
    String? id,
    String? name,
    String? description,
    String? locationId,
    String? imageUrl,
    String? specifications,
    String? status,
    DateTime? createdAt,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      locationId: locationId ?? this.locationId,
      imageUrl: imageUrl ?? this.imageUrl,
      specifications: specifications ?? this.specifications,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
