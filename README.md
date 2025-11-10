# CX6 装置予約システム

研究室での装置予約を管理するWebアプリケーションです。

## 🚀 クイックスタート

### 初回セットアップ

プロジェクトをクローンした後、以下のコマンドで設定ファイルを作成:

**Windows (PowerShell):**
```powershell
Copy-Item lib\src\config\auth_config.dart.example lib\src\config\auth_config.dart
```

**macOS/Linux:**
```bash
cp lib/src/config/auth_config.dart.example lib/src/config/auth_config.dart
```

詳細は **[SETUP.md](SETUP.md)** を参照してください。

---

## 🏗️ アーキテクチャ

### 技術スタック

- **フロントエンド**: Flutter (Web)
- **バックエンド**: Firebase (BaaS)
  - Authentication: ユーザー認証
  - Firestore: NoSQLデータベース
  - Storage: ファイルストレージ（オプション）
  - Hosting: Webアプリホスティング
- **状態管理**: Riverpod
- **アーキテクチャパターン**: MVVM (Model-View-ViewModel)

### プロジェクト構造

```
lib/
├── main.dart                      # エントリーポイント
└── src/
    ├── config/
    │   └── firebase_config.dart   # Firebase設定
    ├── models/                    # ドメインモデル層
    │   ├── user.dart
    │   ├── location.dart          # 場所（部屋）モデル
    │   ├── equipment.dart
    │   └── reservation.dart
    ├── repositories/              # データアクセス層
    │   ├── user_repository.dart
    │   ├── location_repository.dart
    │   ├── equipment_repository.dart
    │   └── reservation_repository.dart
    ├── viewmodels/                # プレゼンテーション層
    │   ├── auth_viewmodel.dart
    │   ├── location_viewmodel.dart
    │   ├── equipment_viewmodel.dart
    │   └── reservation_viewmodel.dart
    ├── views/                     # UI層
    │   ├── login_page.dart
    │   ├── home_page.dart
    │   └── reservation_form_page.dart
    └── utils/
        └── seed_data.dart         # サンプルデータ投入用
```

## 🚀 セットアップ

### 1. 依存関係のインストール

```bash
flutter pub get
```

### 2. Firebase設定

Firebase Consoleで以下を設定済みです：
- プロジェクトID: `cx6-reserver`
- 認証方法: メール/パスワード
- Firestore Database: 有効化
- Firestore Security Rules: 設定済み

### 3. アプリケーションの実行

#### Web版

```bash
flutter run -d chrome
```

または

```bash
flutter run -d edge
```

#### 開発ビルド

```bash
flutter build web
```

#### 本番ビルド

```bash
flutter build web --release
```

## 📱 主な機能

### ユーザー機能

1. **認証**
   - メールアドレスとパスワードでログイン/サインアップ
   - ログアウト

2. **予約確認**
   - 部屋選択ドロップダウン
   - カレンダービューで日付選択
   - 装置ごとの横方向タイムライン表示（0:00〜23:00、40px/時間）
   - 予約状況の視覚的表示

3. **予約作成**
   - 装置選択
   - 日付・時間帯選択（15分単位）
   - メモの追加

4. **予約管理**
   - 自分の予約の確認
   - 予約の削除

### 管理者機能（予定）

- 装置の追加・編集・削除
- 全ユーザーの予約管理
- ユーザー権限管理

## 🗄️ データモデル

### User (ユーザー)

```dart
{
  id: String,           // UID
  name: String,         // 名前
  email: String,        // メールアドレス
  isAdmin: bool,        // 管理者フラグ
  createdAt: DateTime   // 作成日時
}
```

### Location (場所・部屋)

```dart
{
  id: String,           // 場所ID
  name: String,         // 場所名（例: エ4E-104）
  description: String?, // 説明
  createdAt: DateTime   // 作成日時
}
```

### Equipment (装置)

```dart
{
  id: String,           // 装置ID
  name: String,         // 装置名
  description: String,  // 説明
  locationId: String,   // 所在場所ID
  imageUrl: String?,    // 画像URL（オプション）
  specifications: String?, // 仕様（オプション）
  status: String,       // ステータス（available, unavailable等）
  createdAt: DateTime   // 作成日時
}
```

### Reservation (予約)

```dart
{
  id: String,           // 予約ID
  equipmentId: String,  // 装置ID
  equipmentName: String,// 装置名
  userId: String,       // ユーザーID
  userName: String,     // ユーザー名
  startTime: DateTime,  // 開始時刻
  endTime: DateTime,    // 終了時刻
  note: String?,        // メモ（オプション）
  createdAt: DateTime   // 作成日時
}
```

## 🔒 セキュリティルール (Firestore)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ユーザーは認証済みである必要がある
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // ユーザーコレクション
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // 場所コレクション
    match /locations/{locationId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
    
    // 装置コレクション
    match /equipments/{equipmentId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
    
    // 予約コレクション
    match /reservations/{reservationId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
                              (resource.data.userId == request.auth.uid || 
                               get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true);
    }
  }
}
```

## 🛠️ 開発メモ

### サンプルデータの投入

初回セットアップ時に、サンプルの場所と装置データを投入する場合：

```dart
import 'package:cx6_booking_app/src/utils/seed_data.dart';

// Firestore接続後に実行
final seedData = SeedData();
await seedData.seedLocations();  // まず場所を投入
await seedData.seedEquipments(); // 次に装置を投入
```

### デバッグモード

開発中は以下のコマンドでホットリロードを有効にできます：

```bash
flutter run -d chrome --web-renderer html
```

## 📝 今後の拡張予定

- [ ] 管理者画面の実装
- [ ] 予約のリマインダー通知
- [ ] 装置の画像アップロード機能
- [ ] 予約の繰り返し機能
- [ ] エクスポート機能（CSV、PDF）
- [ ] ダークモード対応
- [ ] レスポンシブデザインの改善

## 📄 ライセンス

このプロジェクトは研究室内での利用を目的としています。

