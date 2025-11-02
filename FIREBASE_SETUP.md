# Firebase セットアップガイド

このドキュメントでは、CX6装置予約システムのFirebase設定手順を説明します。

## 📋 事前準備

- Firebaseプロジェクト「cx6-reserver」が作成済みであること
- Firebase Consoleへのアクセス権限があること

## 🔐 1. Firebase Authentication の設定

### 1.1 メール/パスワード認証を有効化

1. [Firebase Console](https://console.firebase.google.com/) を開く
2. プロジェクト「cx6-reserver」を選択
3. 左メニューから「Authentication」を選択
4. 「Sign-in method」タブをクリック
5. 「メール/パスワード」を選択
6. 「有効にする」をONにして「保存」

### 1.2 承認済みドメインの追加

Web版アプリを動作させるには、ホスティングドメインを承認済みリストに追加する必要があります。

1. Authentication > Settings > 承認済みドメイン
2. 以下を追加：
   - `localhost`（開発用）
   - `cx6-reserver.web.app`（本番用）
   - `cx6-reserver.firebaseapp.com`（本番用）

## 🗄️ 2. Cloud Firestore の設定

### 2.1 Firestoreデータベースの作成

1. 左メニューから「Firestore Database」を選択
2. 「データベースを作成」をクリック
3. ロケーションを選択（推奨: `asia-northeast1` - 東京）
4. 「本番環境モードで開始」を選択（後でルールを設定）
5. 「有効にする」をクリック

### 2.2 セキュリティルールの設定

1. Firestore Database > ルール タブ
2. 以下のルールを設定：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 認証済みユーザーのみアクセス可能
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // 管理者かどうか
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
    
    // ユーザーコレクション
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isAuthenticated() && 
                       (request.auth.uid == userId || isAdmin());
      allow delete: if isAdmin();
    }
    
    // 場所コレクション
    match /locations/{locationId} {
      allow read: if isAuthenticated();
      allow create, update, delete: if isAdmin();
    }
    
    // 装置コレクション
    match /equipments/{equipmentId} {
      allow read: if isAuthenticated();
      allow create, update, delete: if isAdmin();
    }
    
    // 予約コレクション
    match /reservations/{reservationId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && 
                       request.resource.data.userId == request.auth.uid;
      allow update, delete: if isAuthenticated() && 
                               (resource.data.userId == request.auth.uid || isAdmin());
    }
  }
}
```

3. 「公開」をクリック

### 2.3 インデックスの作成

効率的なクエリのため、以下のインデックスを作成：

1. Firestore Database > インデックス タブ
2. 「複合」タブで以下を作成：

#### equipments コレクション

| フィールド | 順序 |
|-----------|------|
| location | 昇順 |
| name | 昇順 |

#### reservations コレクション

| フィールド | 順序 |
|-----------|------|
| equipmentId | 昇順 |
| startTime | 昇順 |

| フィールド | 順序 |
|-----------|------|
| userId | 昇順 |
| startTime | 降順 |

| フィールド | 順序 |
|-----------|------|
| startTime | 昇順 |
| equipmentId | 昇順 |

**注意**: 実際にアプリを実行してエラーが出た場合、Firebaseのエラーメッセージに表示されるリンクから自動的に作成できます。

## 📦 3. Cloud Storage の設定（オプション）

装置の画像などをアップロードする場合に使用します。

### 3.1 Storageの有効化

1. 左メニューから「Storage」を選択
2. 「始める」をクリック
3. セキュリティルールのモードを選択
4. ロケーションを選択（Firestoreと同じ推奨）
5. 「完了」をクリック

### 3.2 セキュリティルールの設定

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // 装置画像
    match /equipment_images/{imageId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
  }
}
```

## 🌐 4. Firebase Hosting の設定

### 4.1 Hostingの初期化

ターミナルで以下を実行：

```bash
# Firebase CLIのインストール（未インストールの場合）
npm install -g firebase-tools

# Firebaseにログイン
firebase login

# プロジェクトディレクトリで初期化
cd c:\Users\uttya\myProject\cx6_booking_app
firebase init hosting
```

初期化時の選択：
- プロジェクト: 「cx6-reserver」を選択
- 公開ディレクトリ: `build/web` を入力
- シングルページアプリ: `y`（Yes）
- 自動ビルド: `n`（No）

### 4.2 デプロイ

```bash
# Webアプリをビルド
flutter build web --release

# Firebaseにデプロイ
firebase deploy --only hosting
```

デプロイ後、`https://cx6-reserver.web.app` でアクセス可能になります。

## 🎯 5. 初期データの投入

### 5.1 サンプル場所の追加

アプリにログイン後、ブラウザのコンソールで以下を実行：

```javascript
// Firebase Consoleから直接追加する場合
// Firestore Database > locations コレクション > ドキュメントを追加

{
  name: "エ4E-104",
  description: "4号館1階104号室",
  createdAt: new Date()
}
```

### 5.2 サンプル装置の追加

場所を追加した後、装置を追加します：

```javascript
// まず場所のIDを確認してから
// Firestore Database > equipments コレクション > ドキュメントを追加

{
  name: "SmartLab",
  description: "XRD",
  location: "ZFBkNPmuJA1u4bprsvlS", // 実際の場所IDに置き換え
  status: "available",
  createdAt: new Date()
}

{
  name: "新SmartLab",
  description: "新型スマートラボ装置",
  location: "ZFBkNPmuJA1u4bprsvlS", // 実際の場所IDに置き換え
  status: "available",
  createdAt: new Date()
}
```

または、アプリの管理者機能から追加（実装後）

### 5.3 最初の管理者ユーザーの設定

1. アプリで通常のユーザー登録を行う
2. Firebase Console > Firestore Database
3. `users` コレクション > 該当ユーザーのドキュメント
4. `isAdmin` フィールドを `true` に変更

## 🔍 6. 動作確認

### 6.1 認証のテスト

1. アプリを開く
2. 「アカウントをお持ちでない方はこちら」をクリック
3. 名前、メールアドレス、パスワードを入力して登録
4. ログインできることを確認

### 6.2 予約機能のテスト

1. 部屋を選択
2. カレンダーで日付を選択
3. 横方向のタイムラインに装置が表示されることを確認（サンプルデータがある場合）

### 6.3 Firestoreへのデータ書き込みテスト

1. 予約を新規作成
2. Firebase Console > Firestore Database
3. `reservations` コレクションに新しいドキュメントが追加されたことを確認

## 🚨 トラブルシューティング

### エラー: "Missing or insufficient permissions"

- セキュリティルールが正しく設定されているか確認
- ユーザーが正しくログインしているか確認

### エラー: "CORS policy" 関連

- Firebase Authentication > Settings > 承認済みドメイン に `localhost` が追加されているか確認

### インデックスエラー

- エラーメッセージ内のリンクをクリックして自動作成
- または手動でFirestore Consoleから作成

### 予約の重複チェックが動作しない

- Firestore Security Rulesでデータの読み取り権限があるか確認
- アプリのロジックでバリデーションが実行されているか確認

## 📝 メンテナンス

### 定期的なバックアップ

Firebase Console > Firestore Database > バックアップ から定期バックアップを設定することを推奨します。

### 使用量の監視

Firebase Console > Usage and billing から、以下の使用量を定期的に確認：
- Authentication: ユーザー数
- Firestore: 読み取り/書き込み回数
- Hosting: 転送量
- Storage: ストレージ使用量

### コストの最適化

無料枠（Spark プラン）の範囲：
- Authentication: 制限なし
- Firestore: 1日あたり読み取り50,000回、書き込み20,000回
- Hosting: 1ヶ月あたり10GBの転送量
- Storage: 5GBのストレージ

使用量が増えた場合は、Blaze プラン（従量課金）への移行を検討してください。
