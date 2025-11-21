# フロントエンドアーキテクチャ

## 🧩 MVVMパターン
本アプリケーションは、UIコードとビジネスロジックを分離するために Model-View-ViewModel (MVVM) パターンを使用しています。

### 1. View (UI層)
- `lib/src/views/` に配置。
- Flutter Widgetで構成されます。
- **責務**: ViewModelから提供される状態に基づいてUIを描画します。ユーザー入力を処理し、ロジックをViewModelに委譲します。
- **主要コンポーネント**:
    - `HomePage`: カレンダーとタイムラインを備えたメインダッシュボード。
    - `LoginPage`: 認証画面。
    - `ReservationFormPage`: 予約作成/編集用フォーム。

### 2. ViewModel (プレゼンテーションロジック層)
- `lib/src/viewmodels/` に配置。
- Riverpodの `StateNotifier` を使用して実装されます。
- **責務**: UIの状態を保持し、Viewに公開し、ビジネスロジックを処理します。
- **主要コンポーネント**:
    - `AuthViewModel`: 認証状態を管理。
    - `ReservationViewModel`: 予約ロジック (作成、競合チェック) を処理。
    - `EquipmentViewModel`: 装置データを管理。

### 3. Model (ドメイン層)
- `lib/src/models/` に配置。
- **責務**: データ構造を定義し、シリアライズ/デシリアライズ (Firestore <-> Dartオブジェクト) のメソッドを提供します。
- **主要モデル**: `User`, `Equipment`, `Reservation`, `Location`.

## 🌊 状態管理 (Riverpod)
依存性注入と状態管理にはRiverpodを使用しています。

- **Provider**: 状態へのグローバルなアクセスポイント。
    - `currentUserProvider`: 現在ログインしているユーザーのStream。
    - `reservationsProvider`: 全予約のStream。
    - `selectedDateProvider`: カレンダーで現在選択されている日付の状態。
- **Family Provider**: パラメータ化されたクエリに使用 (例: `reservationsByDateProvider`)。

## 🎨 UIデザインシステム
- **テーマ**: Material 3 デザイン。
- **フォント**: Noto Sans JP (ローカルアセット)。
- **レスポンシブ**: 主にWeb向けに設計されていますが、レスポンシブなWidgetで構築されています。
- **エラーハンドリング**: UI上のすべてのエラーメッセージは、報告を容易にするために `SelectableText` を使用して表示する必要があります。
