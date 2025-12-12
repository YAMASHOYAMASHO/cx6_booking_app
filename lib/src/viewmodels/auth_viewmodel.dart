import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../repositories/allowed_user_repository.dart';

/// FirebaseAuthのプロバイダー
final firebaseAuthProvider = Provider<auth.FirebaseAuth>((ref) {
  return auth.FirebaseAuth.instance;
});

/// 現在のFirebaseユーザーのストリーム
final authStateProvider = StreamProvider<auth.User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// UserRepositoryのプロバイダー
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// 現在のユーザー情報のプロバイダー
final currentUserProvider = StreamProvider<User?>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) {
    return Stream.value(null);
  }
  return ref.watch(userRepositoryProvider).getUserStream(authUser.uid);
});

/// 特定ユーザー情報のプロバイダー（family版）- リアルタイム更新のためStreamProviderを使用
final userByIdProvider = StreamProvider.family<User?, String>((ref, userId) {
  if (userId.isEmpty) return Stream.value(null);
  return ref.watch(userRepositoryProvider).getUserStream(userId);
});

/// 認証ViewModel
class AuthViewModel extends StateNotifier<AsyncValue<void>> {
  final auth.FirebaseAuth _auth;
  final UserRepository _userRepository;
  final AllowedUserRepository _allowedUserRepository;

  AuthViewModel(this._auth, this._userRepository, this._allowedUserRepository)
    : super(const AsyncValue.data(null));

  /// メールとパスワードでサインイン
  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    });
  }

  /// メールとパスワードでサインアップ
  /// studentId: 学籍番号（事前登録確認用）
  Future<void> signUpWithEmail(
    String email,
    String password,
    String name,
    String studentId,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      debugPrint('🔍 [SignUp] 開始: studentId=$studentId, email=$email');

      // 1. 事前登録確認（エラーは AllowedUserRepository から詳細に投げられる）
      debugPrint('📋 [SignUp] Step 1: 事前登録確認中...');
      final allowedUser = await _allowedUserRepository.checkIfAllowed(
        studentId,
      );
      debugPrint(
        '✅ [SignUp] Step 1: 事前登録確認成功 - allowedUser: ${allowedUser?.studentId}',
      );

      // 2. Firebase Authenticationにユーザー作成
      debugPrint('🔐 [SignUp] Step 2: Firebase Auth ユーザー作成中...');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint(
        '✅ [SignUp] Step 2: Firebase Auth ユーザー作成成功 - UID: ${credential.user?.uid}',
      );

      // 3. Firestoreにユーザー情報を保存
      if (credential.user != null) {
        debugPrint('💾 [SignUp] Step 3: Firestore ユーザー情報保存中...');
        debugPrint('   - UID: ${credential.user!.uid}');
        debugPrint('   - Name: $name');
        debugPrint('   - Email: $email');
        debugPrint('   - IsAdmin: false');

        final user = User(
          id: credential.user!.uid,
          name: name,
          email: email,
          isAdmin: false,
          createdAt: DateTime.now(),
        );

        try {
          await _userRepository.saveUser(user);
          debugPrint('✅ [SignUp] Step 3: Firestore ユーザー情報保存成功');
        } catch (e) {
          debugPrint('❌ [SignUp] Step 3: Firestore ユーザー情報保存失敗');
          debugPrint('   - エラー: $e');
          debugPrint('   - エラータイプ: ${e.runtimeType}');
          rethrow;
        }

        // 4. allowedUsersを登録済みに更新
        debugPrint('🏁 [SignUp] Step 4: allowedUsers 登録済みフラグ更新中...');
        try {
          await _allowedUserRepository.markAsRegistered(
            studentId,
            credential.user!.uid,
          );
          debugPrint('✅ [SignUp] Step 4: allowedUsers 登録済みフラグ更新成功');
        } catch (e) {
          debugPrint('❌ [SignUp] Step 4: allowedUsers 登録済みフラグ更新失敗');
          debugPrint('   - エラー: $e');
          rethrow;
        }
      }

      debugPrint('🎉 [SignUp] 全ての処理が完了しました');
    });
  }

  /// サインアウト
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _auth.signOut();
    });
  }

  /// ユーザー情報を更新
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? myColor,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _userRepository.updateUser(userId, name: name, myColor: myColor);
    });
  }

  /// パスワードを変更
  Future<void> changePassword(String newPassword) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('ログインしていません');
      }
      await user.updatePassword(newPassword);
    });
  }

  /// パスワードリセットメールを送信
  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _auth.sendPasswordResetEmail(email: email);
    });
  }
}

/// AuthViewModelのプロバイダー
final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AsyncValue<void>>((ref) {
      return AuthViewModel(
        ref.watch(firebaseAuthProvider),
        ref.watch(userRepositoryProvider),
        ref.watch(allowedUserRepositoryProvider),
      );
    });
