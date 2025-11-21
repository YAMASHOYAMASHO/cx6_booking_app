# データ移行

## 📜 履歴

### [2025-11] ユーザーデータの分離
- **変更**: `reservations` コレクションから `userName` と `userColor` を削除しました。
- **理由**: 過去のデータの不整合を防ぎつつ、ユーザープロファイルの動的な更新を可能にするため。
- **アクション**:
    - `userId` を介してユーザーデータを取得するように `Reservation` モデルを更新しました。
    - レガシーフィールドを削除するための移行スクリプトを作成しました。

## 🛠️ 移行スクリプト
スクリプトは通常、`firebase-admin` を使用したNode.jsスクリプトです。

### 例: レガシーフィールドの削除
```javascript
// 完全なスクリプトについてはレガシーの DATA_MIGRATION.md の内容を参照
batch.update(doc.ref, {
  userName: admin.firestore.FieldValue.delete(),
  userColor: admin.firestore.FieldValue.delete()
});
```

## ⚠️ 手順
1.  **バックアップ**: 移行を実行する前に、必ずFirestoreデータをエクスポートしてください。
2.  **テスト**: まずステージング環境で実行してください。
3.  **実行**: メンテナンスウィンドウ中にスクリプトを実行してください。
