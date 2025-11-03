# Firestoreセキュリティルール更新ガイド

お気に入り機能のために、Firestoreセキュリティルールを更新しました。

## 追加されたルール

### 1. favoriteEquipments コレクション
- ユーザーは自分のお気に入り装置のみ読み書き可能

### 2. favoriteReservationTemplates コレクション
- ユーザーは自分のお気に入り予約テンプレートのみ読み書き可能

## デプロイ方法

### Firebase CLI を使用してデプロイ

```powershell
# Firebase CLIがインストールされていない場合
npm install -g firebase-tools

# Firebaseにログイン
firebase login

# プロジェクトを初期化（初回のみ）
firebase init firestore

# ルールをデプロイ
firebase deploy --only firestore:rules
```

### Firebase Console で手動更新

1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. プロジェクトを選択
3. 左メニューから「Firestore Database」を選択
4. 上部タブの「ルール」をクリック
5. `firestore.rules` ファイルの内容をコピー&ペースト
6. 「公開」ボタンをクリック

## 必要なインデックス

以下の複合インデックスを作成してください：

### favoriteEquipments
```
コレクション: favoriteEquipments
フィールド:
  - userId (昇順)
  - order (昇順)
```

### favoriteReservationTemplates
```
コレクション: favoriteReservationTemplates
フィールド:
  - userId (昇順)
  - updatedAt (降順)
```

## 注意事項

- ルールを更新すると、すぐに全ユーザーに反映されます
- テスト環境で動作確認してから本番環境にデプロイしてください
- ルール更新後、アプリを再起動する必要はありません
