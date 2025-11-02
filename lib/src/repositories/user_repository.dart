import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

/// ユーザーデータのリポジトリ
class UserRepository {
  final FirebaseFirestore _firestore;
  static const String _collectionName = 'users';

  UserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// ユーザー情報を取得
  Future<User?> getUserById(String id) async {
    final doc = await _firestore.collection(_collectionName).doc(id).get();
    if (doc.exists && doc.data() != null) {
      return User.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  /// ユーザー情報を取得（リアルタイム）
  Stream<User?> getUserStream(String id) {
    return _firestore.collection(_collectionName).doc(id).snapshots().map((
      doc,
    ) {
      if (doc.exists && doc.data() != null) {
        return User.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    });
  }

  /// ユーザーを作成または更新
  Future<void> saveUser(User user) async {
    await _firestore
        .collection(_collectionName)
        .doc(user.id)
        .set(user.toFirestore());
  }

  /// ユーザー情報を更新
  Future<void> updateUser(
    String userId, {
    String? name,
    String? myColor,
  }) async {
    final updateData = <String, dynamic>{};
    if (name != null) updateData['name'] = name;
    if (myColor != null) updateData['myColor'] = myColor;

    if (updateData.isNotEmpty) {
      await _firestore
          .collection(_collectionName)
          .doc(userId)
          .update(updateData);
    }
  }

  /// ユーザー全体を更新
  Future<void> saveUserFull(User user) async {
    await _firestore
        .collection(_collectionName)
        .doc(user.id)
        .update(user.toFirestore());
  }

  /// 全ユーザーを取得（管理者用）
  Stream<List<User>> getAllUsersStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => User.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }
}
