import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/favorite_reservation_template.dart';
import '../models/favorite_reservation_execution.dart';
import '../models/reservation.dart';
import '../repositories/favorite_reservation_template_repository.dart';
import '../repositories/reservation_repository.dart';
import 'auth_viewmodel.dart';
import 'reservation_viewmodel.dart';

/// FavoriteReservationTemplateRepositoryのプロバイダー
final favoriteReservationTemplateRepositoryProvider =
    Provider<FavoriteReservationTemplateRepository>((ref) {
      return FavoriteReservationTemplateRepository();
    });

/// テンプレート一覧のプロバイダー
final favoriteReservationTemplatesProvider =
    StreamProvider<List<FavoriteReservationTemplate>>((ref) {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) {
        return Stream.value([]);
      }

      return ref
          .watch(favoriteReservationTemplateRepositoryProvider)
          .getTemplatesStream(user.id);
    });

/// 特定のテンプレートを取得するプロバイダー
final favoriteReservationTemplateProvider =
    FutureProvider.family<FavoriteReservationTemplate?, String>((
      ref,
      templateId,
    ) async {
      return await ref
          .watch(favoriteReservationTemplateRepositoryProvider)
          .getTemplate(templateId);
    });

/// テンプレートViewModel
class FavoriteReservationTemplateViewModel
    extends StateNotifier<AsyncValue<void>> {
  final FavoriteReservationTemplateRepository _templateRepository;
  final ReservationRepository _reservationRepository;
  final String _userId;

  FavoriteReservationTemplateViewModel(
    this._templateRepository,
    this._reservationRepository,
    this._userId,
  ) : super(const AsyncValue.data(null));

  /// テンプレート作成
  Future<String> createTemplate(FavoriteReservationTemplate template) async {
    state = const AsyncValue.loading();

    try {
      final templateId = await _templateRepository.createTemplate(
        userId: _userId,
        name: template.name,
        description: template.description,
        slots: template.slots,
      );
      state = const AsyncValue.data(null);
      return templateId;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// テンプレート更新
  Future<void> updateTemplate(FavoriteReservationTemplate template) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _templateRepository.updateTemplate(
        templateId: template.id,
        name: template.name,
        description: template.description,
        slots: template.slots,
      );
    });
  }

  /// テンプレート削除
  Future<void> deleteTemplate(String templateId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _templateRepository.deleteTemplate(templateId);
    });
  }

  /// 競合チェック
  Future<List<ConflictInfo>> checkConflicts(
    String templateId,
    DateTime baseDate,
  ) async {
    return await _templateRepository.checkConflicts(templateId, baseDate);
  }

  /// テンプレートを実行（一括予約作成）
  Future<ExecutionResult> executeTemplate(
    FavoriteReservationTemplate template,
    DateTime baseDate, {
    bool skipConflicts = false,
  }) async {
    state = const AsyncValue.loading();

    try {
      // 競合チェック
      final conflicts = await checkConflicts(template.id, baseDate);

      // skipConflictsがfalseで競合がある場合はエラー
      if (!skipConflicts && conflicts.isNotEmpty) {
        state = const AsyncValue.data(null);
        return ExecutionResult.conflict(conflicts);
      }

      // 予約を作成
      final createdIds = <String>[];
      final errors = <String>[];

      for (final slot in template.slots) {
        // 競合チェック（skipConflicts=trueの場合はスキップ）
        if (skipConflicts) {
          final slotConflicts = conflicts.where(
            (c) =>
                c.slot.equipmentId == slot.equipmentId &&
                c.slot.dayOffset == slot.dayOffset &&
                c.slot.startTime == slot.startTime,
          );
          if (slotConflicts.isNotEmpty) {
            continue; // この予約はスキップ
          }
        }

        try {
          final startDateTime = slot.getStartDateTime(baseDate);
          final endDateTime = slot.getEndDateTime(baseDate);

          final reservation = Reservation(
            id: '', // Firestoreが自動生成
            userId: _userId,
            equipmentId: slot.equipmentId,
            equipmentName: slot.equipmentName,
            startTime: startDateTime,
            endTime: endDateTime,
            note: (slot.note?.isEmpty ?? true)
                ? '${template.name}より作成'
                : '${template.name}: ${slot.note}',
            createdAt: DateTime.now(),
          );

          final reservationId = await _reservationRepository.addReservation(
            reservation,
          );
          createdIds.add(reservationId);
        } catch (e) {
          errors.add(
            '${slot.equipmentName} (${slot.dayOffset >= 0 ? '+' : ''}${slot.dayOffset}日): $e',
          );
        }
      }

      state = const AsyncValue.data(null);

      if (errors.isEmpty) {
        return ExecutionResult.success(createdIds);
      } else {
        return ExecutionResult.error(errors.join('\n'));
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return ExecutionResult.error('テンプレート実行エラー: $e');
    }
  }

  /// テンプレート実行のプレビュー（実際には作成しない）
  Future<FavoriteReservationExecution> previewExecution(
    FavoriteReservationTemplate template,
    DateTime baseDate,
  ) async {
    final conflicts = await checkConflicts(template.id, baseDate);

    return FavoriteReservationExecution(
      templateId: template.id,
      templateName: template.name,
      baseDate: baseDate,
      slots: template.slots,
      conflicts: conflicts,
    );
  }
}

/// FavoriteReservationTemplateViewModelのプロバイダー
final favoriteReservationTemplateViewModelProvider =
    StateNotifierProvider<
      FavoriteReservationTemplateViewModel,
      AsyncValue<void>
    >((ref) {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      return FavoriteReservationTemplateViewModel(
        ref.watch(favoriteReservationTemplateRepositoryProvider),
        ref.watch(reservationRepositoryProvider),
        user.id,
      );
    });
