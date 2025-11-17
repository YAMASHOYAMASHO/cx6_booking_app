import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/allowed_user.dart';
import '../repositories/allowed_user_repository.dart';

/// 全ての許可ユーザーを取得するプロバイダー
final allowedUsersProvider = StreamProvider<List<AllowedUser>>((ref) {
  final repository = ref.watch(allowedUserRepositoryProvider);
  return repository.getAllowedUsersStream();
});

/// 未登録の許可ユーザーを取得するプロバイダー
final unregisteredAllowedUsersProvider = StreamProvider<List<AllowedUser>>((
  ref,
) {
  final repository = ref.watch(allowedUserRepositoryProvider);
  return repository.getAllowedUsersStreamByStatus(false);
});

/// 登録済みの許可ユーザーを取得するプロバイダー
final registeredAllowedUsersProvider = StreamProvider<List<AllowedUser>>((ref) {
  final repository = ref.watch(allowedUserRepositoryProvider);
  return repository.getAllowedUsersStreamByStatus(true);
});

/// 特定の学籍番号が許可されているか確認するプロバイダー
final checkAllowedProvider = FutureProvider.family<AllowedUser?, String>((
  ref,
  studentId,
) async {
  final repository = ref.watch(allowedUserRepositoryProvider);
  return repository.checkIfAllowed(studentId);
});
