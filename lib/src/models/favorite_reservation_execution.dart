import 'package:intl/intl.dart';
import 'reservation.dart';
import 'reservation_slot.dart';

/// お気に入り予約実行結果
class FavoriteReservationExecution {
  final String templateId; // テンプレートID
  final String templateName; // テンプレート名
  final DateTime baseDate; // 基準日
  final List<ReservationSlot> slots; // 実行するスロット
  final List<ConflictInfo> conflicts; // 競合情報

  FavoriteReservationExecution({
    required this.templateId,
    required this.templateName,
    required this.baseDate,
    required this.slots,
    required this.conflicts,
  });

  /// 実行可能かどうか
  bool get canExecute => conflicts.isEmpty;

  /// 作成される予約の数
  int get reservationCount => slots.length;

  /// 競合数
  int get conflictCount => conflicts.length;

  /// サマリーテキスト
  String get summary {
    if (canExecute) {
      return '✓ 実行可能（${reservationCount}件の予約を作成）';
    } else {
      return '⚠ ${conflictCount}件の競合があります';
    }
  }
}

/// 競合情報
class ConflictInfo {
  final ReservationSlot slot; // 競合するスロット
  final Reservation existingReservation; // 既存の予約

  ConflictInfo({required this.slot, required this.existingReservation});

  /// 競合の説明文
  String get description {
    final startTime = slot.getStartDateTime(existingReservation.startTime);
    final endTime = slot.getEndDateTime(existingReservation.startTime);

    return '${slot.equipmentName}\n'
        '${DateFormat('M/d(E) HH:mm', 'ja_JP').format(startTime)} - '
        '${DateFormat('HH:mm').format(endTime)}\n'
        '既に予約されています';
  }

  /// 競合する装置名
  String get equipmentName => slot.equipmentName;

  /// 競合する日時（テキスト）
  String get conflictTimeText {
    return '${DateFormat('M/d(E) HH:mm', 'ja_JP').format(existingReservation.startTime)} - '
        '${DateFormat('HH:mm').format(existingReservation.endTime)}';
  }

  @override
  String toString() {
    return 'ConflictInfo(equipment: $equipmentName, time: $conflictTimeText)';
  }
}

/// テンプレート実行パラメータ
class TemplateExecutionParams {
  final String templateId;
  final String templateName;
  final DateTime baseDate;
  final List<ReservationSlot> slots;

  TemplateExecutionParams({
    required this.templateId,
    required this.templateName,
    required this.baseDate,
    required this.slots,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateExecutionParams &&
          runtimeType == other.runtimeType &&
          templateId == other.templateId &&
          baseDate == other.baseDate;

  @override
  int get hashCode => templateId.hashCode ^ baseDate.hashCode;
}

/// テンプレート実行結果
class ExecutionResult {
  final bool success;
  final String message;
  final List<ConflictInfo>? conflicts;
  final List<String>? createdReservationIds;

  ExecutionResult({
    required this.success,
    required this.message,
    this.conflicts,
    this.createdReservationIds,
  });

  /// 成功時の結果
  factory ExecutionResult.success(List<String> reservationIds) {
    return ExecutionResult(
      success: true,
      message: '${reservationIds.length}件の予約を作成しました',
      createdReservationIds: reservationIds,
    );
  }

  /// 競合エラー
  factory ExecutionResult.conflict(List<ConflictInfo> conflicts) {
    return ExecutionResult(
      success: false,
      message: '${conflicts.length}件の競合があります',
      conflicts: conflicts,
    );
  }

  /// 一般エラー
  factory ExecutionResult.error(String errorMessage) {
    return ExecutionResult(
      success: false,
      message: 'エラーが発生しました: $errorMessage',
    );
  }

  @override
  String toString() {
    return 'ExecutionResult(success: $success, message: $message)';
  }
}
