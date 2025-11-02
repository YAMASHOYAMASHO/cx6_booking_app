# データマイグレーションガイド

## 概要
ユーザーのマイカラーと名前を動的に取得するように変更したため、Firestoreの`reservations`コレクションから不要な`userName`と`userColor`フィールドを削除する必要があります。

## 変更内容
- **旧実装**: 予約作成時にユーザー名とマイカラーを`Reservation`ドキュメントに保存
- **新実装**: 予約には`userId`のみを保存し、表示時に動的にユーザー情報を取得

## メリット
✅ ユーザーがプロフィールを変更すると、過去の予約も自動的に更新される  
✅ データの重複が減り、整合性が向上  
✅ リアルタイムでユーザー情報が反映される

## 必要な作業
既存の予約データから`userName`と`userColor`フィールドを削除する必要があります。

### オプション1: Firebase Consoleから手動削除（少数の場合）
1. [Firebase Console](https://console.firebase.google.com/)にアクセス
2. プロジェクトを選択
3. 「Firestore Database」を開く
4. `reservations`コレクションを開く
5. 各ドキュメントの`userName`と`userColor`フィールドを削除

### オプション2: スクリプトで一括削除（推奨）
以下のNode.jsスクリプトを使用して一括削除できます：

```javascript
// migration_script.js
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migrateReservations() {
  const reservationsRef = db.collection('reservations');
  const snapshot = await reservationsRef.get();
  
  console.log(`${snapshot.size}件の予約を処理します...`);
  
  const batch = db.batch();
  let count = 0;
  
  snapshot.forEach((doc) => {
    const data = doc.data();
    
    // userName と userColor フィールドが存在する場合のみ削除
    if (data.userName !== undefined || data.userColor !== undefined) {
      batch.update(doc.ref, {
        userName: admin.firestore.FieldValue.delete(),
        userColor: admin.firestore.FieldValue.delete()
      });
      count++;
    }
  });
  
  if (count > 0) {
    await batch.commit();
    console.log(`${count}件の予約を更新しました。`);
  } else {
    console.log('更新が必要な予約はありませんでした。');
  }
}

migrateReservations()
  .then(() => {
    console.log('マイグレーション完了！');
    process.exit(0);
  })
  .catch((error) => {
    console.error('エラー:', error);
    process.exit(1);
  });
```

#### スクリプト実行手順
1. Firebase Admin SDKのサービスアカウントキーをダウンロード
2. 上記スクリプトを`migration_script.js`として保存
3. 必要なパッケージをインストール：
   ```bash
   npm install firebase-admin
   ```
4. スクリプトを実行：
   ```bash
   node migration_script.js
   ```

### オプション3: アプリ起動時に自動削除（開発中のみ推奨）
アプリの初回起動時に自動的にマイグレーションを実行する方法もありますが、本番環境では推奨しません。

## 注意事項
⚠️ **バックアップを取ってから実行してください**  
Firebase Consoleの「エクスポート」機能でデータをバックアップできます。

⚠️ **本番環境では慎重に**  
開発環境で十分テストしてから本番環境で実行してください。

## トラブルシューティング

### ユーザー情報が「不明なユーザー」と表示される
- 該当ユーザーの`userId`が存在しない可能性があります
- Firestoreの`users`コレクションに該当するユーザーが存在するか確認してください

### パフォーマンスが遅い
- `userByIdProvider`はキャッシュされるため、同じユーザーの情報は1回しか取得されません
- 大量の予約がある場合は、タイムラインの表示範囲を制限することを検討してください

## 完了確認
マイグレーション後、以下を確認してください：
1. タイムラインで全ての予約が正しく表示される
2. ユーザー名とマイカラーが正しく反映されている
3. ユーザーがマイページで名前やカラーを変更すると、過去の予約にも反映される
