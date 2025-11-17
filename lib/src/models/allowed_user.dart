import 'package:cloud_firestore/cloud_firestore.dart';

/// 事前登録済みユーザー（登録を許可されたユーザー）
class AllowedUser {
  final String studentId; // 学籍番号（ドキュメントID）
  final String email; // メールアドレス
  final DateTime allowedAt; // 許可日時
  final bool registered; // 登録済みフラグ
  final String? note; // メモ（所属、学年など）

  AllowedUser({
    required this.studentId,
    required this.email,
    required this.allowedAt,
    required this.registered,
    this.note,
  });

  /// Firestoreドキュメントから変換
  factory AllowedUser.fromFirestore(Map<String, dynamic> data, String id) {
    return AllowedUser(
      studentId: id,
      email: data['email'] as String,
      allowedAt: (data['allowedAt'] as Timestamp).toDate(),
      registered: data['registered'] as bool? ?? false,
      note: data['note'] as String?,
    );
  }

  /// Firestoreドキュメントに変換
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'allowedAt': Timestamp.fromDate(allowedAt),
      'registered': registered,
      if (note != null) 'note': note,
    };
  }

  /// コピーを作成
  AllowedUser copyWith({
    String? studentId,
    String? email,
    DateTime? allowedAt,
    bool? registered,
    String? note,
  }) {
    return AllowedUser(
      studentId: studentId ?? this.studentId,
      email: email ?? this.email,
      allowedAt: allowedAt ?? this.allowedAt,
      registered: registered ?? this.registered,
      note: note ?? this.note,
    );
  }

  @override
  String toString() {
    return 'AllowedUser(studentId: $studentId, email: $email, registered: $registered)';
  }
}
