import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart';
import '../repositories/user_repository.dart';

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

/// 認証ViewModel
class AuthViewModel extends StateNotifier<AsyncValue<void>> {
  final auth.FirebaseAuth _auth;
  final UserRepository _userRepository;

  AuthViewModel(this._auth, this._userRepository)
    : super(const AsyncValue.data(null));

  /// メールとパスワードでサインイン
  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    });
  }

  /// メールとパスワードでサインアップ
  Future<void> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestoreにユーザー情報を保存
      if (credential.user != null) {
        final user = User(
          id: credential.user!.uid,
          name: name,
          email: email,
          isAdmin: false,
          createdAt: DateTime.now(),
        );
        await _userRepository.saveUser(user);
      }
    });
  }

  /// サインアウト
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _auth.signOut();
    });
  }
}

/// AuthViewModelのプロバイダー
final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AsyncValue<void>>((ref) {
      return AuthViewModel(
        ref.watch(firebaseAuthProvider),
        ref.watch(userRepositoryProvider),
      );
    });
