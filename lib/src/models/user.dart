/// ユーザーモデル
class User {
  final String id;
  final String name;
  final String email;
  final bool isAdmin;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.isAdmin = false,
    required this.createdAt,
  });

  /// Firestoreのデータから変換
  factory User.fromFirestore(Map<String, dynamic> data, String id) {
    return User(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      isAdmin: data['isAdmin'] ?? false,
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  /// Firestoreへ保存するデータに変換
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'isAdmin': isAdmin,
      'createdAt': createdAt,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    bool? isAdmin,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
