/// 日付範囲を表すモデル
class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end})
    : assert(!end.isBefore(start), '終了日は開始日以降である必要があります');

  /// 期間内の日数
  int get dayCount => end.difference(start).inDays + 1;

  /// 期間内の全ての日付リスト
  List<DateTime> get days {
    return List.generate(dayCount, (index) {
      return DateTime(
        start.year,
        start.month,
        start.day,
      ).add(Duration(days: index));
    });
  }

  /// 指定された日付が範囲内かチェック
  bool contains(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(start.year, start.month, start.day);
    final endOnly = DateTime(end.year, end.month, end.day);
    return !dateOnly.isBefore(startOnly) && !dateOnly.isAfter(endOnly);
  }

  DateRange copyWith({DateTime? start, DateTime? end}) {
    return DateRange(start: start ?? this.start, end: end ?? this.end);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;

  @override
  String toString() => 'DateRange(start: $start, end: $end)';
}
