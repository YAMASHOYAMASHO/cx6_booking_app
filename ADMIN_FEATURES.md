# 管理者画面実装ドキュメント

## 概要
装置予約システムの管理者機能を実装しました。管理者ユーザーは装置の管理、予約の強制削除・変更、場所の管理が可能になりました。

## 実装内容

### 1. 管理者メニュー画面 (`admin_menu_page.dart`)
管理者専用のダッシュボード画面です。

**機能:**
- 装置管理画面への遷移
- 予約管理画面への遷移
- ユーザー管理（今後実装予定）
- 統計情報（今後実装予定）

**アクセス制御:**
- `currentUserProvider`で現在のユーザー情報を取得
- `user.isAdmin`が`true`の管理者のみアクセス可能
- 一般ユーザーがアクセスすると「管理者権限がありません」を表示

### 2. 装置管理画面 (`equipment_management_page.dart`)
装置の一覧表示、追加、編集、削除を行う画面です。

**機能:**
- 装置一覧の表示（カード形式）
  - 装置名、場所、ステータス、メモ、仕様を表示
  - ステータスに応じた色分け（利用可能=緑、メンテナンス中=オレンジ、使用停止=赤）
- 装置の追加（右上の「+」ボタン）
- 装置の編集（各カードの「編集」ボタン）
- 装置の削除（各カードの「削除」ボタン、確認ダイアログあり）
- 場所の追加（右上の「場所追加」ボタン）

**データ構造:**
```dart
Equipment {
  id: String,
  name: String,           // 必須
  description: String,    // メモ
  locationId: String,     // 必須
  status: String,         // 'available' | 'maintenance' | 'unavailable'
  specifications: String?, // 任意
  createdAt: DateTime
}
```

### 3. 装置作成・編集フォーム (`equipment_form_dialog.dart`)
装置の詳細情報を入力するダイアログです。

**入力項目:**
- **装置名** (必須): テキスト入力
- **場所** (必須): ドロップダウン選択
  - 横に「場所追加」ボタンあり
- **メモ** (任意): 複数行テキスト入力
- **仕様** (任意): 複数行テキスト入力
- **ステータス**: ボタン選択
  - 利用可能（緑）
  - メンテナンス中（オレンジ）
  - 使用停止（赤）

**バリデーション:**
- 装置名と場所は必須項目
- 空の場合はエラーメッセージを表示

**使用ViewModel:**
- `equipmentViewModelProvider`: 装置の追加・更新処理

### 4. 場所作成・編集フォーム (`location_form_dialog.dart`)
場所（部屋）を追加・編集する簡易ダイアログです。

**入力項目:**
- **場所名** (必須): テキスト入力

**データ構造:**
```dart
Location {
  id: String,
  name: String,
  createdAt: DateTime
}
```

**使用ViewModel:**
- `locationViewModelProvider`: 場所の追加・更新処理

### 5. 予約管理画面 (`reservation_management_page.dart`)
ホーム画面と同じデザインで、管理者が全ユーザーの予約を削除・変更できる画面です。

**機能:**
- ホーム画面と同じ横方向タイムライン表示
  - カレンダーで日付選択
  - 場所選択ドロップダウン
  - 装置ごとの予約バー表示
- 予約バークリックでボトムシート表示
  - 予約詳細の表示（装置、予約者、時間、メモ）
  - **編集ボタン**: 予約フォームへ遷移
  - **削除ボタン**: 確認ダイアログ後、予約を強制削除

**特徴:**
- 一般ユーザーは自分の予約のみ編集可能
- 管理者はすべての予約を編集・削除可能
- タイムライン表示: 1時間=40px、24時間表示、横スクロール可能

**使用Provider:**
- `selectedLocationIdProvider`: 管理画面専用の場所選択（String?型）
- `equipmentsByLocationProvider`: 場所ごとの装置リスト
- `reservationsProvider`: 全予約リスト
- `reservationViewModelProvider`: 予約の削除処理

### 6. ホーム画面への管理者メニュー追加
一般ユーザー向けホーム画面に管理者メニューボタンを追加しました。

**実装:**
```dart
// 管理者のみ表示
currentUser.whenOrNull(
  data: (user) {
    if (user != null && user.isAdmin) {
      return IconButton(
        icon: const Icon(Icons.admin_panel_settings),
        onPressed: () => Navigator.push(...),
        tooltip: '管理者メニュー',
      );
    }
    return null;
  },
) ?? const SizedBox.shrink(),
```

## ViewModelの構造

### EquipmentViewModel
```dart
class EquipmentViewModel extends StateNotifier<AsyncValue<void>> {
  Future<void> addEquipment(Equipment equipment);
  Future<void> updateEquipment(Equipment equipment);
  Future<void> deleteEquipment(String id);
}
```

### LocationViewModel
```dart
class LocationViewModel extends StateNotifier<AsyncValue<void>> {
  Future<void> addLocation(Location location);
  Future<void> updateLocation(Location location);
  Future<void> deleteLocation(String id);
}
```

### ReservationViewModel
```dart
class ReservationViewModel extends StateNotifier<AsyncValue<void>> {
  Future<void> addReservation(Reservation reservation);
  Future<void> updateReservation(Reservation reservation);
  Future<void> deleteReservation(String id);
}
```

## Provider一覧

### 既存Provider
- `equipmentsProvider`: StreamProvider<List<Equipment>> - 全装置リスト
- `locationsProvider`: StreamProvider<List<Location>> - 全場所リスト
- `reservationsProvider`: StreamProvider<List<Reservation>> - 全予約リスト
- `currentUserProvider`: StreamProvider<User?> - 現在のユーザー情報

### 管理画面用Provider
- `selectedLocationIdProvider`: StateProvider<String?> - 管理画面用の場所選択
- `selectedLocationProvider`: StateProvider<Location?> - ホーム画面用の場所選択

### Family Provider
- `equipmentsByLocationProvider(locationId)`: 特定場所の装置リスト
- `reservationsByEquipmentProvider(equipmentId)`: 特定装置の予約リスト

## Firebase Firestore構造

### collections
```
locations/
  {locationId}/
    - name: String
    - createdAt: Timestamp

equipments/
  {equipmentId}/
    - name: String
    - description: String
    - location: String (locationId)
    - status: String
    - specifications: String?
    - imageUrl: String?
    - createdAt: Timestamp

reservations/
  {reservationId}/
    - equipmentId: String
    - equipmentName: String
    - userId: String
    - userName: String
    - startTime: Timestamp
    - endTime: Timestamp
    - note: String?
    - createdAt: Timestamp

users/
  {userId}/
    - name: String
    - email: String
    - isAdmin: Boolean
    - createdAt: Timestamp
```

## 管理者権限の設定方法

1. Firebaseコンソールで`users`コレクションを開く
2. 管理者にしたいユーザーのドキュメントを選択
3. `isAdmin`フィールドを`true`に変更

## エラーハンドリング

すべてのエラーは`SelectableText`で表示され、ユーザーがコピー可能です。
- Firebase URLを含むエラーメッセージも選択可能
- エラーは赤い枠とアイコン付きで表示
- monospaceフォントで技術的な情報を読みやすく

## 今後の実装予定

1. **ユーザー管理画面**
   - ユーザー一覧表示
   - 管理者権限の付与・削除
   - ユーザーの無効化

2. **統計情報画面**
   - 装置利用率の表示
   - 予約数の推移グラフ
   - ユーザー別利用統計

3. **装置画像アップロード**
   - Firebase Storageへの画像アップロード
   - 装置カードでの画像表示

4. **一括操作**
   - 複数装置の一括ステータス変更
   - 複数予約の一括削除

5. **通知機能**
   - 予約リマインダー
   - メンテナンス予定の通知

## ファイル構成

```
lib/src/views/admin/
  ├── admin_menu_page.dart           # 管理者メニュー
  ├── equipment_management_page.dart  # 装置管理
  ├── equipment_form_dialog.dart      # 装置フォーム
  ├── location_form_dialog.dart       # 場所フォーム
  └── reservation_management_page.dart # 予約管理
```

## 使用方法

1. 管理者権限を持つユーザーでログイン
2. ホーム画面右上の「管理者パネル」アイコン（歯車マーク）をクリック
3. 管理者メニューから各機能にアクセス

### 装置の追加
1. 管理者メニュー > 装置管理
2. 右上の「+」ボタンをクリック
3. 装置情報を入力
4. ステータスを選択
5. 「保存」ボタンをクリック

### 予約の削除
1. 管理者メニュー > 予約管理
2. カレンダーで日付を選択
3. 場所を選択
4. 削除したい予約バーをクリック
5. ボトムシートで「削除」ボタンをクリック
6. 確認ダイアログで「削除」をクリック
