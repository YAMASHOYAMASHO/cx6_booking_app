# UI変更・データモデル更新ログ

## 📅 更新日: 2025年11月2日

## 🎯 主な変更内容

### 1. データモデルの変更

#### 新規追加: Location (場所・部屋) モデル
- **ファイル**: `lib/src/models/location.dart`
- **目的**: 装置の所在場所を管理
- **フィールド**:
  - `id`: 場所ID
  - `name`: 場所名（例: エ4E-104）
  - `description`: 説明（オプション）
  - `createdAt`: 作成日時

#### 更新: Equipment (装置) モデル
- **ファイル**: `lib/src/models/equipment.dart`
- **変更内容**:
  - `isAvailable` (bool) → `status` (String) に変更
    - 'available', 'unavailable' などの文字列で状態を管理
  - `locationId` フィールドを追加（必須）
    - 装置が所属する場所のIDを保持
  - `specifications` フィールドを追加（オプション）
    - 装置の仕様情報を保存
- **理由**: Firestoreのデータ構造に合わせ、より柔軟な状態管理を実現

### 2. リポジトリ層の追加・更新

#### 新規追加: LocationRepository
- **ファイル**: `lib/src/repositories/location_repository.dart`
- **機能**:
  - 場所データのCRUD操作
  - リアルタイム更新のサポート

#### 更新: EquipmentRepository
- **ファイル**: `lib/src/repositories/equipment_repository.dart`
- **追加メソッド**:
  - `getEquipmentsByLocationStream(String locationId)`: 特定の場所の装置を取得
- **変更内容**:
  - `isAvailable` → `status` フィールドへの変更に対応

### 3. ViewModel層の追加・更新

#### 新規追加: LocationViewModel
- **ファイル**: `lib/src/viewmodels/location_viewmodel.dart`
- **プロバイダー**:
  - `locationsProvider`: 全場所リストのストリーム
  - `selectedLocationProvider`: 選択中の場所の状態管理

#### 更新: EquipmentViewModel
- **ファイル**: `lib/src/viewmodels/equipment_viewmodel.dart`
- **追加プロバイダー**:
  - `equipmentsByLocationProvider`: 特定の場所の装置リスト

### 4. UI層の大幅変更: HomePage

#### 変更前の構造
```
┌────────────────┬──────────────────────┐
│ 装置選択       │ 日付表示             │
│ カレンダー     │ ┌─────────────────┐ │
│                │ │ 縦方向タイムライン│ │
│                │ │ (60px/時間)      │ │
│                │ │ 00:00-23:59      │ │
│                │ └─────────────────┘ │
└────────────────┴──────────────────────┘
```

#### 変更後の構造
```
┌────────────────┬──────────────────────────────────────┐
│ 部屋選択       │ 日付表示                             │
│ カレンダー     │ ┌───┬──────────────────────────┐ │
│                │ │装置│ 横方向タイムライン       │ │
│                │ │名  │ 00 01 02 ... 23 (40px/h)│ │
│                │ ├───┼──────────────────────────┤ │
│                │ │装置│ [予約バー]              │ │
│                │ │名  │                         │ │
│                │ └───┴──────────────────────────┘ │
└────────────────┴──────────────────────────────────────┘
```

#### 主な変更点

1. **装置選択 → 部屋選択**
   - ドロップダウンで部屋を選択
   - 選択した部屋に所属する全装置を表示

2. **タイムラインの方向転換**
   - **縦方向 → 横方向** に変更
   - 縦軸: 装置リスト
   - 横軸: 時間（0時〜23時）

3. **タイムライン表示の変更**
   - **60px/時間 → 40px/時間** に変更
   - 時間表示: **04:00 → 04** (「:00」を削除)
   - グリッド線: 6時間ごとに太線

4. **スクロール対応**
   - 横方向にスクロール可能
   - `Scrollbar` ウィジェットでスクロールバーを常時表示
   - `thumbVisibility: true` で視認性を向上

5. **装置行の表示**
   - 各装置ごとに1行を占有
   - 装置名の左に状態インジケーター（緑/灰色の四角）
   - 行の高さ: 60px（固定）

6. **予約バーの表示**
   - 開始時刻と終了時刻から位置と幅を計算
   - `left = startHour × 40px`
   - `width = duration × 40px`
   - ユーザー名とメモを表示（幅が十分な場合のみ）

### 5. ユーティリティの更新

#### SeedData クラス
- **ファイル**: `lib/src/utils/seed_data.dart`
- **追加メソッド**:
  - `seedLocations()`: サンプル場所データの投入
- **変更内容**:
  - `seedEquipments()`: 場所IDを参照するように変更
  - `clearAllData()`: 場所データの削除を追加

### 6. コードの主要な変更箇所

#### home_page.dart の新しいウィジェット構造

```dart
HomePage
├── _LocationSelector        # 部屋選択ドロップダウン
├── _MonthCalendar           # カレンダー
├── _DateNavigationButtons   # 日付移動ボタン
└── _TimelineView            # タイムライン全体
    └── _HorizontalTimelineGrid  # 横方向タイムライングリッド
        ├── _buildTimeHeader()        # 時間軸ヘッダー
        ├── _buildEquipmentRow()      # 装置行（複数）
        │   └── _buildReservationBar() # 予約バー（複数）
        └── _showReservationDialog()   # 予約詳細ダイアログ
```

## 🔧 技術的な詳細

### タイムライン計算ロジック

```dart
// 時間軸の位置計算
const double hourWidth = 40.0;  // 1時間 = 40px

// 予約バーの左端位置
final startHour = startTime.hour + startTime.minute / 60.0;
final left = startHour * hourWidth;

// 予約バーの幅
final endHour = endTime.hour + endTime.minute / 60.0;
final duration = endHour - startHour;
final width = duration * hourWidth;

// 例: 9:30-11:45 の予約
// startHour = 9.5, endHour = 11.75
// left = 9.5 × 40 = 380px
// width = 2.25 × 40 = 90px
```

### グリッド描画

```dart
// 24時間分のグリッド
Row(
  children: List.generate(24, (hour) {
    return Container(
      width: hourWidth,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Colors.grey[300]!,
            width: hour % 6 == 0 ? 1.5 : 0.5, // 6時間ごとに太線
          ),
        ),
      ),
      child: Text(hour.toString().padLeft(2, '0')),
    );
  }),
)
```

### スクロールバーの実装

```dart
Scrollbar(
  thumbVisibility: true,  // スクロールバーを常に表示
  child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,  // 横スクロール
    child: SizedBox(
      width: 24 * hourWidth + 120,  // 24時間 + 装置名幅
      child: /* タイムライン内容 */,
    ),
  ),
)
```

## 📊 Firestore データ構造の変更

### locations コレクション（新規）

```javascript
{
  "name": "エ4E-104",
  "description": "4号館1階104号室",
  "createdAt": Timestamp
}
```

### equipments コレクション（変更）

**変更前:**
```javascript
{
  "name": "SmartLab",
  "description": "スマートラボ装置",
  "isAvailable": true,
  "createdAt": Timestamp
}
```

**変更後:**
```javascript
{
  "name": "SmartLab",
  "description": "XRD",
  "location": "ZFBkNPmuJA1u4bprsvlS",  // 場所ID（必須）
  "status": "available",                // 文字列に変更
  "specifications": null,               // 仕様（オプション）
  "imageUrl": null,                     // 画像URL（オプション）
  "createdAt": Timestamp
}
```

## 🔐 セキュリティルールの追加

```javascript
// locations コレクション
match /locations/{locationId} {
  allow read: if isAuthenticated();
  allow create, update, delete: if isAdmin();
}

// equipments コレクション（更新）
match /equipments/{equipmentId} {
  allow read: if isAuthenticated();
  allow create, update, delete: if isAdmin();
}
```

## 📝 必要なインデックス（追加）

### equipments コレクション
- `location` (昇順) + `name` (昇順)

既存のインデックスはそのまま維持。

## 🎨 UIの視覚的変更

### 時間表示の変更
- **変更前**: 00:00, 01:00, 02:00, ...
- **変更後**: 00, 01, 02, ...

### グリッド線
- 通常: 0.5px (薄い灰色)
- 6時間ごと: 1.5px (濃い灰色)

### 装置名の表示
- 左側に固定列（120px幅）
- 状態インジケーター（12×12pxの四角）
  - 緑: 利用可能 (status === 'available')
  - 灰色: 利用不可

### 予約バー
- 背景色: `Colors.blue[100]`
- 枠線: `Colors.blue`, 1.5px
- 角丸: 4px
- パディング: 左右4px、上下2px
- テキスト:
  - ユーザー名: 11px, 太字
  - メモ: 10px, 通常（幅が60px以上の場合のみ表示）

## 🚀 今後の改善案

1. **パフォーマンス最適化**
   - 仮想スクロールの実装
   - 大量の装置/予約がある場合の描画最適化

2. **UI/UX向上**
   - ドラッグ&ドロップでの予約作成
   - 予約バーのリサイズ機能
   - ズームイン/ズームアウト機能

3. **機能追加**
   - 装置の絞り込み/検索
   - 予約の色分け（ユーザーごと、ステータスごと）
   - 現在時刻のインジケーター表示

4. **レスポンシブ対応**
   - モバイル版のレイアウト最適化
   - タブレットサイズへの対応

## ✅ 動作確認チェックリスト

- [ ] 部屋選択ドロップダウンが正常に動作する
- [ ] 選択した部屋の装置が全て表示される
- [ ] 横方向タイムラインが正しく描画される
- [ ] 時間表示が「04」形式になっている
- [ ] 予約バーが正しい位置と幅で表示される
- [ ] 横スクロールが正常に動作する
- [ ] スクロールバーが常時表示される
- [ ] 予約をクリックすると詳細ダイアログが表示される
- [ ] 予約の削除が正常に動作する（自分の予約または管理者）

## 📚 関連ドキュメント

- `README.md`: プロジェクト概要（更新済み）
- `FIREBASE_SETUP.md`: Firebase設定ガイド（更新済み）
- `IMPLEMENTATION.md`: 実装詳細（今後更新予定）
