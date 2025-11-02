# マイカラー機能のデータ移行ガイド

## 変更内容

予約データに `userColor` フィールドを追加しました。これにより、各ユーザーの予約がそれぞれのマイカラーで表示されます。

## 新機能の動作

### タイムライン表示
- **他人の予約**: そのユーザーのマイカラーで表示される（透明度30%）
- **自分の予約**: 
  - マイカラーで表示
  - 枠線が太い（3px）
  - 影付きで目立つ
  - ユーザーアイコン付き
  - ユーザー名が太字で色付き

### 管理画面
- 全ての予約がそれぞれのユーザーのマイカラーで表示される

## 既存データの移行

### 方法1: 新規予約の自動対応（推奨）
新しく作成される予約には自動的に `userColor` が含まれます。既存の予約は、次回更新時に自動的に更新されます。

**特徴:**
- 自動的に移行される
- システム負荷が低い
- 段階的な移行

**制約:**
- 既存の予約は更新されるまでデフォルト色（青）で表示される

### 方法2: Firebase Consoleから手動更新
既存の予約データに `userColor` を手動で追加できます。

**手順:**
1. [Firebase Console](https://console.firebase.google.com/) を開く
2. Firestore Database → `reservations` コレクション
3. 各ドキュメントを開く
4. `userColor` フィールドを追加
5. ユーザーの `users` コレクションから該当ユーザーの `myColor` をコピー
6. 値を保存

### 方法3: スクリプトで一括移行（開発者向け）

Firebase Admin SDKを使用して一括移行するスクリプト例：

```javascript
// migration_script.js
const admin = require('firebase-admin');
const serviceAccount = require('./path-to-service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migrateReservations() {
  try {
    // 全ての予約を取得
    const reservationsSnapshot = await db.collection('reservations').get();
    
    console.log(`全予約数: ${reservationsSnapshot.size}`);
    
    let updated = 0;
    let skipped = 0;
    
    for (const reservationDoc of reservationsSnapshot.docs) {
      const reservation = reservationDoc.data();
      
      // userColorが既にある場合はスキップ
      if (reservation.userColor) {
        skipped++;
        continue;
      }
      
      // ユーザー情報を取得
      const userDoc = await db.collection('users').doc(reservation.userId).get();
      
      if (!userDoc.exists) {
        console.log(`ユーザーが見つかりません: ${reservation.userId}`);
        skipped++;
        continue;
      }
      
      const user = userDoc.data();
      
      // userColorを更新
      await reservationDoc.ref.update({
        userColor: user.myColor || null
      });
      
      updated++;
      
      if (updated % 10 === 0) {
        console.log(`進捗: ${updated}件更新, ${skipped}件スキップ`);
      }
    }
    
    console.log('移行完了！');
    console.log(`更新: ${updated}件`);
    console.log(`スキップ: ${skipped}件`);
    
  } catch (error) {
    console.error('エラー:', error);
  }
}

migrateReservations()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

**実行方法:**
```bash
# Firebase Admin SDKをインストール
npm install firebase-admin

# サービスアカウントキーをダウンロード
# Firebase Console → プロジェクト設定 → サービスアカウント → 新しい秘密鍵の生成

# スクリプトを実行
node migration_script.js
```

## データ構造

### 変更前
```json
{
  "id": "reservation_id",
  "equipmentId": "equipment_id",
  "equipmentName": "装置名",
  "userId": "user_id",
  "userName": "ユーザー名",
  "startTime": "2025-11-03T09:00:00Z",
  "endTime": "2025-11-03T10:00:00Z",
  "note": "備考",
  "createdAt": "2025-11-03T08:00:00Z"
}
```

### 変更後
```json
{
  "id": "reservation_id",
  "equipmentId": "equipment_id",
  "equipmentName": "装置名",
  "userId": "user_id",
  "userName": "ユーザー名",
  "userColor": "#FF5733",  // ← 追加
  "startTime": "2025-11-03T09:00:00Z",
  "endTime": "2025-11-03T10:00:00Z",
  "note": "備考",
  "createdAt": "2025-11-03T08:00:00Z"
}
```

## トラブルシューティング

### 予約が青色のまま表示される
**原因**: 予約データに `userColor` がない、またはユーザーが `myColor` を設定していない

**解決策**:
1. ユーザーがマイページでマイカラーを設定
2. 予約を作り直すか、上記の移行方法で `userColor` を追加

### 色が正しく表示されない
**原因**: `userColor` の形式が不正（`#RRGGBB` 形式でない）

**解決策**:
1. Firebase Consoleで該当の予約を確認
2. `userColor` が `#` で始まる6桁の16進数であることを確認
3. 例: `#FF5733`, `#3498DB`, `#2ECC71`

## 注意事項

- **後方互換性**: `userColor` が `null` または空の場合、デフォルトの青色で表示されます
- **パフォーマンス**: 大量の予約（1000件以上）がある場合、方法3のスクリプト移行を推奨します
- **データ整合性**: 移行前にFirestoreのバックアップを取ることを推奨します

## バックアップ方法

Firebase Consoleから:
1. Firestore Database → データタブ
2. 右上のメニュー → データのエクスポート
3. エクスポート先のバケットを選択
4. 「エクスポート」をクリック
