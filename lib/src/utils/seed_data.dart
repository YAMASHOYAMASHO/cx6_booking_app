import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 初期データを投入するヘルパークラス
class SeedData {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// サンプル場所を追加
  Future<void> seedLocations() async {
    final locations = [
      {'name': 'エ4E-104', 'createdAt': DateTime.now()},
    ];

    for (var location in locations) {
      // 既に存在するか確認
      final existing = await _firestore
          .collection('locations')
          .where('name', isEqualTo: location['name'])
          .get();

      if (existing.docs.isEmpty) {
        await _firestore.collection('locations').add(location);
        debugPrint('場所を追加しました: ${location['name']}');
      } else {
        debugPrint('場所は既に存在します: ${location['name']}');
      }
    }
  }

  /// サンプル装置を追加
  Future<void> seedEquipments() async {
    // まず場所を取得
    final locationSnapshot = await _firestore
        .collection('locations')
        .where('name', isEqualTo: 'エ4E-104')
        .limit(1)
        .get();

    if (locationSnapshot.docs.isEmpty) {
      debugPrint('場所が見つかりません。先にseedLocations()を実行してください。');
      return;
    }

    final locationId = locationSnapshot.docs.first.id;

    final equipments = [
      {
        'name': 'SmartLab',
        'description': 'XRD',
        'location': locationId,
        'status': 'available',
        'specifications': null,
        'createdAt': DateTime.now(),
      },
      {
        'name': '新SmartLab',
        'description': '新型スマートラボ装置',
        'location': locationId,
        'status': 'available',
        'specifications': null,
        'createdAt': DateTime.now(),
      },
    ];

    for (var equipment in equipments) {
      // 既に存在するか確認
      final existing = await _firestore
          .collection('equipments')
          .where('name', isEqualTo: equipment['name'])
          .get();

      if (existing.docs.isEmpty) {
        await _firestore.collection('equipments').add(equipment);
        debugPrint('装置を追加しました: ${equipment['name']}');
      } else {
        debugPrint('装置は既に存在します: ${equipment['name']}');
      }
    }
  }

  /// サンプル予約を追加（テスト用）
  Future<void> seedReservations(String userId, String userName) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // SmartLabのIDを取得
    final equipmentSnapshot = await _firestore
        .collection('equipments')
        .where('name', isEqualTo: 'SmartLab')
        .limit(1)
        .get();

    if (equipmentSnapshot.docs.isEmpty) {
      debugPrint('装置が見つかりません。先にseedEquipments()を実行してください。');
      return;
    }

    final equipmentId = equipmentSnapshot.docs.first.id;
    final equipmentName = equipmentSnapshot.docs.first.data()['name'] as String;

    final reservations = [
      {
        'equipmentId': equipmentId,
        'equipmentName': equipmentName,
        'userId': userId,
        'userName': userName,
        'startTime': today.add(const Duration(hours: 6)),
        'endTime': today.add(const Duration(hours: 9)),
        'note': 'サンプル予約1',
        'createdAt': DateTime.now(),
      },
      {
        'equipmentId': equipmentId,
        'equipmentName': equipmentName,
        'userId': userId,
        'userName': userName,
        'startTime': today.add(const Duration(hours: 12)),
        'endTime': today.add(const Duration(hours: 15)),
        'note': 'サンプル予約2',
        'createdAt': DateTime.now(),
      },
    ];

    for (var reservation in reservations) {
      await _firestore.collection('reservations').add(reservation);
      debugPrint(
        '予約を追加しました: ${reservation['startTime']} - ${reservation['endTime']}',
      );
    }
  }

  /// 全データをクリア（開発用）
  Future<void> clearAllData() async {
    // 予約を削除
    final reservations = await _firestore.collection('reservations').get();
    for (var doc in reservations.docs) {
      await doc.reference.delete();
    }
    debugPrint('予約データを削除しました (${reservations.docs.length}件)');

    // 装置を削除
    final equipments = await _firestore.collection('equipments').get();
    for (var doc in equipments.docs) {
      await doc.reference.delete();
    }
    debugPrint('装置データを削除しました (${equipments.docs.length}件)');

    // 場所を削除
    final locations = await _firestore.collection('locations').get();
    for (var doc in locations.docs) {
      await doc.reference.delete();
    }
    debugPrint('場所データを削除しました (${locations.docs.length}件)');
  }
}
