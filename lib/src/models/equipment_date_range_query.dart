/// 装置IDと日付範囲を指定するクエリ
class EquipmentDateRangeQuery {
  final String equipmentId;
  final DateTime startDate;
  final DateTime endDate;

  EquipmentDateRangeQuery({
    required this.equipmentId,
    required this.startDate,
    required this.endDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquipmentDateRangeQuery &&
          runtimeType == other.runtimeType &&
          equipmentId == other.equipmentId &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode =>
      equipmentId.hashCode ^ startDate.hashCode ^ endDate.hashCode;

  @override
  String toString() =>
      'EquipmentDateRangeQuery(equipmentId: $equipmentId, startDate: $startDate, endDate: $endDate)';
}
