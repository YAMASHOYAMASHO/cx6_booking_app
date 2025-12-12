import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/allowed_user.dart';

/// AllowedUserRepositoryのプロバイダー
final allowedUserRepositoryProvider = Provider<AllowedUserRepository>((ref) {
  return AllowedUserRepository();
});

/// 事前登録ユーザーのリポジトリ
class AllowedUserRepository {
  final FirebaseFirestore _firestore;
  static const String _collectionName = 'allowedUsers';

  AllowedUserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 学籍番号が登録許可されているか確認
  Future<AllowedUser?> checkIfAllowed(String studentId) async {
    debugPrint('🔍 [AllowedUserRepo] checkIfAllowed 開始: studentId=$studentId');
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(studentId)
          .get();

      debugPrint('📄 [AllowedUserRepo] ドキュメント取得: exists=${doc.exists}');

      if (!doc.exists || doc.data() == null) {
        debugPrint('❌ [AllowedUserRepo] ドキュメントが存在しません');
        throw Exception('この学籍番号は登録が許可されていません。管理者にお問い合わせください。');
      }

      final allowedUser = AllowedUser.fromFirestore(doc.data()!, doc.id);
      debugPrint('📋 [AllowedUserRepo] allowedUser取得成功:');
      debugPrint('   - studentId: ${allowedUser.studentId}');
      debugPrint('   - email: ${allowedUser.email}');
      debugPrint('   - registered: ${allowedUser.registered}');
      debugPrint('   - allowedAt: ${allowedUser.allowedAt}');

      // すでに登録済みの場合はエラー
      if (allowedUser.registered) {
        debugPrint('❌ [AllowedUserRepo] 既に登録済みです');
        throw Exception('この学籍番号は既に登録済みです。ログインしてください。');
      }

      debugPrint('✅ [AllowedUserRepo] 登録可能です');
      return allowedUser;
    } catch (e) {
      debugPrint('⚠️ [AllowedUserRepo] エラー発生: $e');
      // 既に適切なエラーメッセージの場合はそのまま再スロー
      if (e.toString().contains('登録が許可されていません') ||
          e.toString().contains('既に登録済み')) {
        rethrow;
      }
      throw Exception('登録確認中にエラーが発生しました: $e');
    }
  }

  /// 登録済みフラグを更新
  Future<void> markAsRegistered(String studentId, String userId) async {
    try {
      await _firestore.collection(_collectionName).doc(studentId).update({
        'registered': true,
        'registeredAt': FieldValue.serverTimestamp(),
        'userId': userId,
      });
    } catch (e) {
      throw Exception('登録済みフラグの更新中にエラーが発生しました: $e');
    }
  }

  /// 個別に許可ユーザーを追加
  Future<void> addAllowedUser(AllowedUser user) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(user.studentId)
          .set(user.toFirestore());
    } catch (e) {
      throw Exception('許可ユーザーの追加中にエラーが発生しました: $e');
    }
  }

  /// CSVデータから一括追加
  /// csvData: [{'studentId': '123456', 'note': '情報科学科'}, ...]
  Future<int> addAllowedUsersFromCsv(List<Map<String, String>> csvData) async {
    try {
      final batch = _firestore.batch();
      int count = 0;

      for (final row in csvData) {
        final studentId = row['studentId']?.trim();
        final note = row['note']?.trim();

        if (studentId == null || studentId.isEmpty) {
          continue; // 学籍番号が空の行はスキップ
        }

        final email = '$studentId@stu.kobe-u.ac.jp';
        final allowedUser = AllowedUser(
          studentId: studentId,
          email: email,
          allowedAt: DateTime.now(),
          registered: false,
          note: note?.isNotEmpty == true ? note : null,
        );

        final docRef = _firestore.collection(_collectionName).doc(studentId);

        batch.set(docRef, allowedUser.toFirestore());
        count++;
      }

      await batch.commit();
      return count;
    } catch (e) {
      throw Exception('CSV一括追加中にエラーが発生しました: $e');
    }
  }

  /// 全ての許可ユーザーを取得（ストリーム）
  Stream<List<AllowedUser>> getAllowedUsersStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('allowedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AllowedUser.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  /// 許可ユーザーを削除
  Future<void> deleteAllowedUser(String studentId) async {
    try {
      await _firestore.collection(_collectionName).doc(studentId).delete();
    } catch (e) {
      throw Exception('許可ユーザーの削除中にエラーが発生しました: $e');
    }
  }

  /// 複数の許可ユーザーを削除
  Future<void> deleteAllowedUsers(List<String> studentIds) async {
    try {
      final batch = _firestore.batch();

      for (final studentId in studentIds) {
        final docRef = _firestore.collection(_collectionName).doc(studentId);
        batch.delete(docRef);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('許可ユーザーの一括削除中にエラーが発生しました: $e');
    }
  }

  /// 登録済み/未登録でフィルタリング
  Stream<List<AllowedUser>> getAllowedUsersStreamByStatus(bool registered) {
    return _firestore
        .collection(_collectionName)
        .where('registered', isEqualTo: registered)
        .orderBy('allowedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AllowedUser.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }
}
