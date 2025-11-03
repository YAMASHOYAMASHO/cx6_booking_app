import 'package:flutter/material.dart';

/// 予約スロット（お気に入り予約テンプレート内の1つの予約）
class ReservationSlot {
  final String equipmentId; // 装置ID
  final String equipmentName; // 装置名（キャッシュ）
  final int dayOffset; // 基準日からの日数オフセット（0=当日, 1=翌日, -1=前日）
  final TimeOfDay startTime; // 開始時刻
  final TimeOfDay endTime; // 終了時刻
  final String? note; // メモ（オプション）
  final int order; // 実行順序

  ReservationSlot({
    required this.equipmentId,
    required this.equipmentName,
    required this.dayOffset,
    required this.startTime,
    required this.endTime,
    this.note,
    this.order = 0,
  });

  /// JSON形式に変換
  Map<String, dynamic> toJson() {
    return {
      'equipmentId': equipmentId,
      'equipmentName': equipmentName,
      'dayOffset': dayOffset,
      'startTime': {'hour': startTime.hour, 'minute': startTime.minute},
      'endTime': {'hour': endTime.hour, 'minute': endTime.minute},
      'note': note,
      'order': order,
    };
  }

  /// JSONから変換
  factory ReservationSlot.fromJson(Map<String, dynamic> json) {
    final startTimeData = json['startTime'] as Map<String, dynamic>;
    final endTimeData = json['endTime'] as Map<String, dynamic>;

    return ReservationSlot(
      equipmentId: json['equipmentId'] as String,
      equipmentName: json['equipmentName'] as String,
      dayOffset: json['dayOffset'] as int,
      startTime: TimeOfDay(
        hour: startTimeData['hour'] as int,
        minute: startTimeData['minute'] as int,
      ),
      endTime: TimeOfDay(
        hour: endTimeData['hour'] as int,
        minute: endTimeData['minute'] as int,
      ),
      note: json['note'] as String?,
      order: json['order'] as int? ?? 0,
    );
  }

  /// 実際の開始日時を計算
  DateTime getStartDateTime(DateTime baseDate) {
    final targetDate = baseDate.add(Duration(days: dayOffset));
    return DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      startTime.hour,
      startTime.minute,
    );
  }

  /// 実際の終了日時を計算
  DateTime getEndDateTime(DateTime baseDate) {
    final targetDate = baseDate.add(Duration(days: dayOffset));
    return DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      endTime.hour,
      endTime.minute,
    );
  }

  /// 予約の期間を計算
  Duration get duration {
    final start = DateTime(2000, 1, 1, startTime.hour, startTime.minute);
    final end = DateTime(2000, 1, 1, endTime.hour, endTime.minute);
    return end.difference(start);
  }

  /// 日付オフセットのテキスト表現
  String get dayOffsetText {
    if (dayOffset == 0) return '当日';
    if (dayOffset == 1) return '翌日';
    if (dayOffset == -1) return '前日';
    if (dayOffset > 0) return '$dayOffset日後';
    return '${dayOffset.abs()}日前';
  }

  /// バリデーション
  String? validate() {
    // 時間の妥当性チェック
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (startMinutes >= endMinutes) {
      return '終了時刻は開始時刻より後である必要があります';
    }

    // dayOffsetの範囲チェック（±30日以内）
    if (dayOffset < -30 || dayOffset > 30) {
      return '日付オフセットは±30日以内で指定してください';
    }

    return null;
  }

  /// コピー
  ReservationSlot copyWith({
    String? equipmentId,
    String? equipmentName,
    int? dayOffset,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? note,
    int? order,
  }) {
    return ReservationSlot(
      equipmentId: equipmentId ?? this.equipmentId,
      equipmentName: equipmentName ?? this.equipmentName,
      dayOffset: dayOffset ?? this.dayOffset,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      note: note ?? this.note,
      order: order ?? this.order,
    );
  }

  @override
  String toString() {
    return 'ReservationSlot(equipment: $equipmentName, dayOffset: $dayOffset, '
        'time: ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')} - '
        '${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReservationSlot &&
          runtimeType == other.runtimeType &&
          equipmentId == other.equipmentId &&
          dayOffset == other.dayOffset &&
          startTime == other.startTime &&
          endTime == other.endTime;

  @override
  int get hashCode =>
      equipmentId.hashCode ^
      dayOffset.hashCode ^
      startTime.hashCode ^
      endTime.hashCode;
}
