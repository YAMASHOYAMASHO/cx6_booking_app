# 装置別予約タイムライン - アーキテクチャ設計

## 概要
特定の装置の1～2週間の予約状況をタイムライン形式で表示する機能

## ディレクトリ構成

```
lib/src/
├── views/
│   ├── home_page.dart                    # 既存: 日別・装置別タイムライン
│   ├── equipment_timeline_page.dart       # 新規: 装置別・日別タイムライン
│   └── widgets/                          # 新規: 共通ウィジェット
│       ├── location_selector.dart         # 部屋選択ドロップダウン
│       ├── equipment_selector.dart        # 装置選択ドロップダウン（新規）
│       ├── date_calendar.dart            # カレンダーウィジェット
│       └── timeline_grid.dart            # タイムライングリッド（横向き、時間軸）
├── viewmodels/
│   ├── equipment_timeline_viewmodel.dart  # 新規: 装置タイムライン用ViewModel
│   └── (既存のViewModelを活用)
└── models/
    └── (既存のモデルを活用)
```

## コンポーネント設計

### 1. **EquipmentTimelinePage** (新規画面)
**責務**: 装置別の予約タイムライン画面全体の構成

**レイアウト構造**:
```
┌─────────────────────────────────────────────────┐
│ AppBar: 装置別予約タイムライン                      │
├─────────────────┬───────────────────────────────┤
│                 │                               │
│  左サイドバー      │   中央: タイムライングリッド        │
│  ┌───────────┐  │   ┌─────────────────────┐   │
│  │部屋選択    │  │   │   0:00  6:00  12:00 │   │
│  │ ▼ 東館1F   │  │   ├─────────────────────┤   │
│  └───────────┘  │   │2025/11/03 ████░░░░░░│   │
│  ┌───────────┐  │   │2025/11/04 ░░██████░░│   │
│  │装置選択    │  │   │2025/11/05 ░░░░████░░│   │
│  │ ▼ 装置A    │  │   │2025/11/06           │   │
│  └───────────┘  │   │   ...               │   │
│                 │   └─────────────────────┘   │
│  カレンダー      │                               │
│  ┌───────────┐  │   スクロール可能（横・縦）        │
│  │ [11月]    │  │                               │
│  │  1  2  3  │  │                               │
│  │  ...      │  │                               │
│  └───────────┘  │                               │
└─────────────────┴───────────────────────────────┘
```

### 2. **共通ウィジェット（リファクタリング）**

#### 2.1 LocationSelector (既存から抽出)
```dart
class LocationSelector extends ConsumerWidget {
  final String? selectedLocationId;
  final ValueChanged<String?> onLocationChanged;
  
  // 部屋選択ドロップダウンの共通ウィジェット
}
```

#### 2.2 EquipmentSelector (新規)
```dart
class EquipmentSelector extends ConsumerWidget {
  final String locationId;
  final String? selectedEquipmentId;
  final ValueChanged<String?> onEquipmentChanged;
  
  // 装置選択ドロップダウン
}
```

#### 2.3 DateCalendar (既存から抽出)
```dart
class DateCalendar extends ConsumerWidget {
  final DateTime selectedDate;
  final DateTime focusedDate;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onPageChanged;
  
  // カレンダーウィジェット（table_calendar使用）
}
```

#### 2.4 TimelineGrid (共通化・拡張)
```dart
enum TimelineOrientation {
  equipmentsByDate,  // 既存: 横軸=時間、縦軸=装置（home_page）
  datesByTime,       // 新規: 横軸=時間、縦軸=日付（equipment_timeline_page）
}

class TimelineGrid extends ConsumerWidget {
  final TimelineOrientation orientation;
  final DateTime? selectedDate;  // equipmentsByDate用
  final String? equipmentId;     // datesByTime用
  final DateRange? dateRange;    // datesByTime用（開始日～終了日）
  
  // タイムライングリッドの共通ウィジェット
  // orientationに応じて表示を切り替え
}
```

### 3. **ViewModel層**

#### 3.1 selectedEquipmentProvider (新規)
```dart
final selectedEquipmentProvider = StateProvider<String?>((ref) => null);
```

#### 3.2 dateRangeProvider (新規)
```dart
final dateRangeProvider = StateProvider<DateRange>((ref) {
  final today = DateTime.now();
  return DateRange(
    start: today,
    end: today.add(const Duration(days: 14)), // 2週間
  );
});
```

#### 3.3 reservationsByEquipmentAndDateRangeProvider (新規)
```dart
final reservationsByEquipmentAndDateRangeProvider = 
    StreamProvider.family<List<Reservation>, EquipmentDateRangeQuery>(
  (ref, query) {
    return ref
        .watch(reservationRepositoryProvider)
        .getReservationsByEquipmentAndDateRange(
          query.equipmentId,
          query.startDate,
          query.endDate,
        );
  },
);
```

### 4. **Repository層の拡張**

#### ReservationRepository に追加
```dart
/// 特定の装置の期間内予約を取得
Stream<List<Reservation>> getReservationsByEquipmentAndDateRange(
  String equipmentId,
  DateTime startDate,
  DateTime endDate,
) {
  final endOfLastDay = DateTime(
    endDate.year,
    endDate.month,
    endDate.day,
    23, 59, 59,
  );
  
  return _firestore
      .collection(_collectionName)
      .where('equipmentId', isEqualTo: equipmentId)
      .where('startTime', isGreaterThanOrEqualTo: startDate)
      .where('startTime', isLessThan: endOfLastDay)
      .orderBy('startTime')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => Reservation.fromFirestore(doc.data(), doc.id))
            .toList();
      });
}
```

### 5. **モデル層の拡張**

#### DateRange (新規モデル)
```dart
class DateRange {
  final DateTime start;
  final DateTime end;
  
  DateRange({required this.start, required this.end});
  
  int get dayCount => end.difference(start).inDays + 1;
  
  List<DateTime> get days {
    return List.generate(dayCount, (index) {
      return start.add(Duration(days: index));
    });
  }
}
```

#### EquipmentDateRangeQuery (新規)
```dart
class EquipmentDateRangeQuery {
  final String equipmentId;
  final DateTime startDate;
  final DateTime endDate;
  
  EquipmentDateRangeQuery({
    required this.equipmentId,
    required this.startDate,
    required this.endDate,
  });
}
```

## 実装フェーズ

### Phase 1: 共通ウィジェットの抽出
1. ✅ `home_page.dart`から部屋選択部分を`LocationSelector`として抽出
2. ✅ カレンダー部分を`DateCalendar`として抽出
3. ✅ タイムライングリッドの共通化検討

### Phase 2: Repository/ViewModel拡張
1. ✅ `DateRange`モデルの作成
2. ✅ `ReservationRepository`に期間検索メソッド追加
3. ✅ 装置選択・期間選択用Providerの作成

### Phase 3: 新規画面の実装
1. ✅ `EquipmentTimelinePage`の基本構造
2. ✅ `EquipmentSelector`ウィジェットの作成
3. ✅ 装置別・日別タイムライングリッドの実装

### Phase 4: ナビゲーション統合
1. ✅ AppBarまたはDrawerに「装置別タイムライン」メニュー追加
2. ✅ 画面遷移の実装

## 再利用性のポイント

### 既存コードの再利用
- `Reservation`モデル: そのまま使用
- `Equipment`モデル: そのまま使用
- `Location`モデル: そのまま使用
- `reservationsByDateProvider`: 参考にする
- `selectedLocationProvider`: 共有して使用

### 新規コンポーネントの汎用性
- `TimelineGrid`: orientationパラメータで2つの表示モードを切り替え
- `LocationSelector`, `EquipmentSelector`: どの画面でも再利用可能
- `DateCalendar`: 他の日付選択画面でも使用可能

### デザインの一貫性
- タイムラインの1時間あたりの幅（hourWidth）を定数化
- 行の高さ（rowHeight）を定数化
- 色設定をテーマから取得
- マイカラー表示ロジックを共通化

## Firestore クエリの考慮事項

### 複合インデックスの必要性
```
Collection: reservations
Fields: equipmentId (Ascending), startTime (Ascending)
```

このインデックスをFirebase Consoleで作成する必要があります。

## パフォーマンス最適化

### データ取得の最適化
- 2週間分のデータのみ取得（不要なデータを取得しない）
- StreamProviderでリアルタイム更新
- 装置選択時のみクエリ実行（未選択時は空表示）

### 描画の最適化
- `RepaintBoundary`でタイムライン部分を分離
- スクロール時の再描画を最小化
- 大量の予約がある場合の仮想スクロール検討

## テスト観点

### 単体テスト
- `DateRange`の日数計算
- 期間内予約の取得ロジック
- 重複チェックが正しく動作するか

### 統合テスト
- 部屋選択 → 装置選択の連携
- カレンダーでの期間変更
- 予約の作成・更新・削除がタイムラインに反映されるか

### UIテスト
- 2週間分のデータが正しく表示されるか
- スクロール動作が滑らか
- レスポンシブデザイン（画面サイズ変更）

## 今後の拡張性

### 将来的な機能追加
- 📅 期間の変更（1週間、1ヶ月など）
- 📊 予約状況の統計表示
- 📤 CSV/PDF出力
- 🔍 予約の検索・フィルタリング
- 📱 モバイル対応の最適化

### デザインの変更容易性
共通ウィジェットを使用することで、以下が容易に：
- タイムラインのグリッドスタイル変更
- 色設定の統一的な変更
- レイアウトの調整

## まとめ

このアーキテクチャにより：
1. ✅ **再利用性**: 既存コードを最大限活用
2. ✅ **拡張性**: 将来の機能追加が容易
3. ✅ **保守性**: 共通ウィジェット化で変更が一箇所で済む
4. ✅ **一貫性**: デザインの統一性を保持
5. ✅ **パフォーマンス**: 必要なデータのみ取得・描画

次のステップ: Phase 1から順次実装を開始します。
