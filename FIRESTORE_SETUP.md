# Firestore セキュリティルールのデプロイ手順

## 問題の説明
ログイン時に「Missing or insufficient permissions」エラーが発生する問題は、Firestoreのセキュリティルールが適切に設定されていないことが原因です。

## 解決方法

### 方法1: Firebaseコンソールから設定（推奨）

1. [Firebase Console](https://console.firebase.google.com/) を開く
2. プロジェクトを選択
3. 左メニューから「Firestore Database」を選択
4. 「ルール」タブをクリック
5. `firestore.rules` ファイルの内容をコピー＆ペースト
6. 「公開」ボタンをクリック

### 方法2: Firebase CLIを使用（開発環境に推奨）

```bash
# Firebase CLIをインストール（初回のみ）
npm install -g firebase-tools

# Firebaseにログイン
firebase login

# プロジェクトを初期化（初回のみ）
firebase init firestore

# ルールをデプロイ
firebase deploy --only firestore:rules
```

## セキュリティルールの概要

作成した `firestore.rules` では以下のアクセス制御を実装しています：

### ユーザー（users）
- **読み取り**: 認証済みユーザー全員
- **作成**: 新規サインアップ時に自分のドキュメントのみ
- **更新**: 自分のドキュメントのみ
- **削除**: 管理者のみ

### 場所（locations）
- **読み取り**: 認証済みユーザー全員
- **作成・更新・削除**: 管理者のみ

### 装置（equipments）
- **読み取り**: 認証済みユーザー全員
- **作成・更新・削除**: 管理者のみ

### 予約（reservations）
- **読み取り**: 認証済みユーザー全員
- **作成**: 自分のuserIdの予約のみ
- **更新**: 自分の予約または管理者
- **削除**: 自分の予約または管理者

## アプリ側の改善

以下のViewModelで認証状態を確認するように修正しました：

- `location_viewmodel.dart`: locationsProvider
- `equipment_viewmodel.dart`: equipmentsProvider, availableEquipmentsProvider, equipmentsByLocationProvider
- `reservation_viewmodel.dart`: reservationsProvider, reservationsByDateProvider, reservationsByEquipmentProvider, reservationsByUserProvider
- `home_page.dart`: 認証状態の確認とエラーハンドリング

これにより、認証が完了する前にFirestoreへのアクセスが発生しないようになります。

## テスト環境での注意

開発・テスト環境で全てのアクセスを許可したい場合は、以下のルールを一時的に使用できます（本番環境では使用しないでください）：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## トラブルシューティング

### エラーが継続する場合

1. ブラウザのキャッシュをクリア
2. アプリをリロード
3. 一度ログアウトして再ログイン
4. Firebase Consoleでルールが正しく適用されているか確認

### 管理者権限の設定

最初の管理者ユーザーは、Firebase Consoleから直接Firestoreのusersコレクションで `isAdmin: true` を設定する必要があります。

1. Firebase Console → Firestore Database
2. `users` コレクションから該当ユーザーを選択
3. `isAdmin` フィールドを追加し、値を `true` に設定
