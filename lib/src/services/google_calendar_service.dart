import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

/// Googleカレンダー連携サービス
class GoogleCalendarService {
  /// 単一予約をGoogleカレンダーに登録するURLを開く
  ///
  /// [equipmentName] 装置名（イベントタイトルになる）
  /// [startTime] 開始時刻
  /// [endTime] 終了時刻
  /// [note] 備考（イベントの説明になる）
  static Future<void> addSingleReservation({
    required String equipmentName,
    required DateTime startTime,
    required DateTime endTime,
    String? note,
  }) async {
    final url = _buildGoogleCalendarUrl(
      title: equipmentName,
      startTime: startTime,
      endTime: endTime,
      description: note,
    );

    await _launchUrl(url);
  }

  /// テンプレート予約をGoogleカレンダーに登録するURLを開く
  ///
  /// [templateName] テンプレート名（イベントタイトルになる）
  /// [equipmentNames] 予約した装置名のリスト
  /// [earliestStartTime] 最も早い開始時刻
  /// [latestEndTime] 最も遅い終了時刻
  /// [notes] 各予約の備考（装置名とペアで表示）
  static Future<void> addTemplateReservation({
    required String templateName,
    required List<String> equipmentNames,
    required DateTime earliestStartTime,
    required DateTime latestEndTime,
    List<String?>? notes,
  }) async {
    // 説明を構築
    final buffer = StringBuffer();

    // 装置一覧
    buffer.writeln('【予約装置一覧】');
    for (int i = 0; i < equipmentNames.length; i++) {
      buffer.writeln('・${equipmentNames[i]}');
    }

    // 備考があれば追加
    if (notes != null) {
      final nonEmptyNotes = notes
          .where((n) => n != null && n.isNotEmpty)
          .toList();
      if (nonEmptyNotes.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('【備考】');
        for (final note in nonEmptyNotes) {
          buffer.writeln(note);
        }
      }
    }

    final url = _buildGoogleCalendarUrl(
      title: templateName,
      startTime: earliestStartTime,
      endTime: latestEndTime,
      description: buffer.toString(),
    );

    await _launchUrl(url);
  }

  /// GoogleカレンダーのURLを構築
  static String _buildGoogleCalendarUrl({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
  }) {
    // 日時をGoogleカレンダー形式に変換（YYYYMMDDTHHmmss）
    final dateFormat = DateFormat("yyyyMMdd'T'HHmmss");
    final startStr = dateFormat.format(startTime);
    final endStr = dateFormat.format(endTime);

    // URLパラメータを構築
    final params = <String, String>{
      'action': 'TEMPLATE',
      'text': title,
      'dates': '$startStr/$endStr',
    };

    if (description != null && description.isNotEmpty) {
      params['details'] = description;
    }

    // URLを構築
    final uri = Uri.https('calendar.google.com', '/calendar/render', params);

    return uri.toString();
  }

  /// URLを開く
  static Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('[GoogleCalendarService] URLを開けませんでした: $url');
      }
    } catch (e) {
      debugPrint('[GoogleCalendarService] エラー: $e');
    }
  }
}
