/// 予約モデル
class Reservation {
  final String id;
  final String equipmentId;
  final String equipmentName;
  final String userId;
  final String userName;
  final DateTime startTime;
  final DateTime endTime;
  final String? note;
  final DateTime createdAt;

  Reservation({
    required this.id,
    required this.equipmentId,
    required this.equipmentName,
    required this.userId,
    required this.userName,
    required this.startTime,
    required this.endTime,
    this.note,
    required this.createdAt,
  });

  /// Firestoreのデータから変換
  factory Reservation.fromFirestore(Map<String, dynamic> data, String id) {
    return Reservation(
      id: id,
      equipmentId: data['equipmentId'] ?? '',
      equipmentName: data['equipmentName'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      startTime: (data['startTime'] as dynamic)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as dynamic)?.toDate() ?? DateTime.now(),
      note: data['note'],
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  /// Firestoreへ保存するデータに変換
  Map<String, dynamic> toFirestore() {
    return {
      'equipmentId': equipmentId,
      'equipmentName': equipmentName,
      'userId': userId,
      'userName': userName,
      'startTime': startTime,
      'endTime': endTime,
      'note': note,
      'createdAt': createdAt,
    };
  }

  /// 予約時間の長さ（時間単位）
  double get durationInHours {
    return endTime.difference(startTime).inMinutes / 60.0;
  }

  /// 予約が現在進行中か
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// 予約が過去のものか
  bool get isPast {
    return DateTime.now().isAfter(endTime);
  }

  Reservation copyWith({
    String? id,
    String? equipmentId,
    String? equipmentName,
    String? userId,
    String? userName,
    DateTime? startTime,
    DateTime? endTime,
    String? note,
    DateTime? createdAt,
  }) {
    return Reservation(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      equipmentName: equipmentName ?? this.equipmentName,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
