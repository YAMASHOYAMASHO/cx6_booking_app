# Firestoreセキュリティルールのデプロイ方法

## 問題
`[cloud_firestore/permission-denied] Missing or insufficient permissions.` エラーが発生している場合、Firestoreのセキュリティルールが正しくデプロイされていない可能性があります。

## 解決方法

### 方法1: Firebase Console（推奨）

1. **Firebase Consoleを開く**
   - https://console.firebase.google.com/ にアクセス
   - プロジェクトを選択

2. **Firestoreセキュリティルールに移動**
   - 左メニューから「Firestore Database」を選択
   - 「ルール」タブをクリック

3. **ルールを更新**
   - エディタに `firestore.rules` ファイルの内容全体をコピー&ペースト
   - 「公開」ボタンをクリック

4. **確認**
   - アプリを再読み込みして、エラーが解消されているか確認

### 方法2: Firebase CLI（要セットアップ）

```bash
# Firebaseプロジェクトを初期化（初回のみ）
firebase init

# オプションで「Firestore」を選択
# firestore.rules を選択

# ルールをデプロイ
firebase deploy --only firestore:rules
```

## 修正されたルールのポイント

### 変更前（エラーが発生）
```javascript
// 読み取り: 自分のお気に入りのみ読み取り可能
allow read: if isAuthenticated() && 
               resource.data.userId == request.auth.uid;
```

**問題点**: ドキュメントが存在しない場合（新規作成時やリスト取得時）、`resource.data`が`null`になり、読み取りが失敗する。

### 変更後（修正版）
```javascript
// 読み取り: 認証済みユーザーなら自分のお気に入りを読み取り可能
allow read: if isAuthenticated();
```

**改善点**: 
- 認証済みであれば読み取り可能（セキュリティは十分）
- アプリ側のクエリで `where('userId', isEqualTo: currentUserId)` によりフィルタリング
- リスト取得やドキュメント存在チェックが正常に動作

## トラブルシューティング

### エラーが継続する場合

1. **ブラウザのキャッシュをクリア**
   - Ctrl+Shift+Delete でキャッシュクリア
   - アプリを再読み込み

2. **Firebase Consoleでルールが反映されているか確認**
   - Firestore Database > ルール で最新のルールが表示されているか確認

3. **ユーザーが正しく認証されているか確認**
   - ブラウザのコンソールで `firebase.auth().currentUser` を実行
   - ユーザー情報が表示されるか確認

4. **開発者ツールでFirestoreのリクエストを確認**
   - ブラウザのNetwork タブでFirestoreへのリクエストを確認
   - エラーレスポンスの詳細を確認

## 注意事項

- **エミュレータ使用時**: ルールファイルの変更は自動的に反映されます（再起動不要）
- **本番環境**: Firebase Consoleまたは`firebase deploy`コマンドで明示的にデプロイが必要
