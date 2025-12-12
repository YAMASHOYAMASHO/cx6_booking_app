import 'package:intl/intl.dart';
import '../models/reservation.dart';

/// キャッシュエントリ
class CacheEntry<T> {
  final T data;
  final DateTime fetchedAt;
  final Duration ttl;

  CacheEntry({required this.data, required this.fetchedAt, required this.ttl});

  /// キャッシュが期限切れかどうか
  bool get isExpired => DateTime.now().difference(fetchedAt) > ttl;

  /// 残り有効時間
  Duration get remainingTtl {
    final elapsed = DateTime.now().difference(fetchedAt);
    final remaining = ttl - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

/// 予約キャッシュサービス
///
/// Firestoreの読み取り数を削減するためのローカルキャッシュ。
/// TTL（デフォルト10分）経過後、またはデータ更新検知時にキャッシュを無効化する。
///
/// 重要: 予約の重複チェック（_checkConflicts）はキャッシュを使用せず、
/// 常にFirestoreから最新データを取得して確認する。
class ReservationCacheService {
  /// デフォルトのTTL（10分）
  static const Duration defaultTtl = Duration(minutes: 10);

  /// 装置×日付ごとのキャッシュ
  final Map<String, CacheEntry<List<Reservation>>> _equipmentDateCache = {};

  /// ユーザーごとのキャッシュ
  final Map<String, CacheEntry<List<Reservation>>> _userCache = {};

  /// 日付フォーマッター
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  // ============================================================
  // キャッシュキー生成
  // ============================================================

  /// 装置×日付のキャッシュキー
  String _equipmentDateKey(String equipmentId, DateTime date) {
    return 'eq_${equipmentId}_${_dateFormat.format(date)}';
  }

  /// 装置×日付範囲のキャッシュキー
  String _equipmentDateRangeKey(
    String equipmentId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return 'eq_${equipmentId}_${_dateFormat.format(startDate)}_${_dateFormat.format(endDate)}';
  }

  /// ユーザーのキャッシュキー
  String _userKey(String userId) {
    return 'user_$userId';
  }

  // ============================================================
  // 装置×日付範囲キャッシュ操作
  // ============================================================

  /// 装置×日付範囲のキャッシュを取得
  List<Reservation>? getByEquipmentAndDateRange(
    String equipmentId,
    DateTime startDate,
    DateTime endDate,
  ) {
    final key = _equipmentDateRangeKey(equipmentId, startDate, endDate);
    final entry = _equipmentDateCache[key];

    if (entry == null) {
      return null;
    }

    if (entry.isExpired) {
      _equipmentDateCache.remove(key);
      return null;
    }

    return entry.data;
  }

  /// 装置×日付範囲のキャッシュを設定
  void setByEquipmentAndDateRange(
    String equipmentId,
    DateTime startDate,
    DateTime endDate,
    List<Reservation> data, {
    Duration? ttl,
  }) {
    final key = _equipmentDateRangeKey(equipmentId, startDate, endDate);
    _equipmentDateCache[key] = CacheEntry(
      data: data,
      fetchedAt: DateTime.now(),
      ttl: ttl ?? defaultTtl,
    );
  }

  /// 装置に関連するキャッシュを無効化
  void invalidateByEquipment(String equipmentId) {
    _equipmentDateCache.removeWhere(
      (key, _) => key.contains('eq_$equipmentId'),
    );
  }

  /// 装置×日付のキャッシュを無効化
  void invalidateByEquipmentAndDate(String equipmentId, DateTime date) {
    final dateStr = _dateFormat.format(date);
    _equipmentDateCache.removeWhere(
      (key, _) => key.contains('eq_$equipmentId') && key.contains(dateStr),
    );
  }

  // ============================================================
  // ユーザーキャッシュ操作
  // ============================================================

  /// ユーザーのキャッシュを取得
  List<Reservation>? getByUser(String userId) {
    final key = _userKey(userId);
    final entry = _userCache[key];

    if (entry == null) {
      return null;
    }

    if (entry.isExpired) {
      _userCache.remove(key);
      return null;
    }

    return entry.data;
  }

  /// ユーザーのキャッシュを設定
  void setByUser(String userId, List<Reservation> data, {Duration? ttl}) {
    final key = _userKey(userId);
    _userCache[key] = CacheEntry(
      data: data,
      fetchedAt: DateTime.now(),
      ttl: ttl ?? defaultTtl,
    );
  }

  /// ユーザーのキャッシュを無効化
  void invalidateByUser(String userId) {
    _userCache.remove(_userKey(userId));
  }

  // ============================================================
  // 全体操作
  // ============================================================

  /// 全キャッシュをクリア
  void invalidateAll() {
    _equipmentDateCache.clear();
    _userCache.clear();
  }

  /// 期限切れキャッシュを削除（メモリ最適化）
  void cleanupExpired() {
    _equipmentDateCache.removeWhere((_, entry) => entry.isExpired);
    _userCache.removeWhere((_, entry) => entry.isExpired);
  }

  /// キャッシュ統計情報（デバッグ用）
  Map<String, dynamic> get stats => {
    'equipmentDateCacheSize': _equipmentDateCache.length,
    'userCacheSize': _userCache.length,
    'equipmentDateKeys': _equipmentDateCache.keys.toList(),
    'userKeys': _userCache.keys.toList(),
  };
}
