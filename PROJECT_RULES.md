# プロジェクト開発ルール

## 🔴 最重要ルール

### 1. エラーメッセージは必ずテキスト選択可能な形式で表示すること

**理由**: ユーザーがエラーメッセージをコピーして検索、報告、デバッグできるようにするため

**実装方法**:
- ❌ **NG**: `Text('エラー: $error')`
- ✅ **OK**: `SelectableText('エラー: $error')`

**推奨テンプレート**:
```dart
// シンプルなエラー表示
error: (error, stack) => SelectableText(
  'エラー: $error',
  style: const TextStyle(
    color: Colors.red,
    fontFamily: 'monospace',
  ),
),

// 詳細なエラー表示（推奨）
error: (error, stack) => Center(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error, color: Colors.red, size: 48),
        const SizedBox(height: 16),
        const Text(
          'エラーが発生しました',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SelectableText(
          '$error',
          style: const TextStyle(
            color: Colors.red,
            fontFamily: 'monospace',
          ),
        ),
        if (stack != null) ...[
          const SizedBox(height: 16),
          ExpansionTile(
            title: const Text('スタックトレース'),
            children: [
              SelectableText(
                '$stack',
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  ),
),
```

**適用箇所**:
- すべての`.when()`の`error`ハンドラー
- `AsyncValue`のエラー表示
- `try-catch`ブロックのエラー表示
- SnackBarのエラーメッセージ（重要度が高い場合）
- Dialogのエラーメッセージ

---

### 2. Firestoreクエリでは複合インデックスを避ける

**理由**: インデックス作成の手間を減らし、開発速度を上げるため

**実装方法**:
- ❌ **NG**: `.where('userId', isEqualTo: userId).orderBy('updatedAt', descending: true)`
- ✅ **OK**: `.where('userId', isEqualTo: userId)` + クライアント側ソート

**推奨パターン**:
```dart
// クエリ実行
Stream<List<MyModel>> getModelsStream(String userId) {
  return _firestore
      .collection('myCollection')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) {
        final models = snapshot.docs
            .map((doc) => MyModel.fromFirestore(doc))
            .toList();
        
        // クライアント側でソート（インデックス不要）
        models.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return models;
      });
}
```

**許可されるインデックス不要なクエリ**:
- 単一フィールドの`where`のみ
- `orderBy`のみ（`where`なし）
- `limit`のみ

**インデックスが必要になるケース（要検討）**:
- `where` + `orderBy`の組み合わせ
- 複数の`where`条件
- `where` + `orderBy` + `limit`

---

### 3. 認証状態の確認を徹底する

**実装方法**:
```dart
// ViewModelやRepositoryでユーザーIDを取得する場合
final user = ref.watch(currentUserProvider).value;
if (user == null) {
  return Stream.value([]); // または適切なデフォルト値
}
```

---

### 4. エラーハンドリングの徹底

**実装方法**:
```dart
// 非同期処理では必ずtry-catchを使用
try {
  await someAsyncOperation();
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('成功しました')),
    );
  }
} catch (e) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SelectableText('エラー: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

---

## 📋 コーディング規約

### Dart/Flutter

1. **命名規則**
   - クラス: `PascalCase`
   - 関数・変数: `camelCase`
   - 定数: `camelCase` (Flutter標準に従う)
   - プライベート: `_camelCase`

2. **ファイル構成**
   - models/ - データモデル
   - repositories/ - データアクセス層
   - viewmodels/ - ビジネスロジック層
   - views/ - UI層

3. **コメント**
   - 公開API: DartDoc形式 (`///`)
   - 内部実装: 必要に応じて `//`

### Firestore

1. **コレクション名**
   - 複数形、camelCase: `users`, `favoriteEquipments`

2. **セキュリティルール**
   - 必ず認証チェック: `isAuthenticated()`
   - 所有者チェック: `isOwner(userId)`
   - 管理者チェック: `isAdmin()`

---

## 🔍 デバッグとテスト

### ログ出力
```dart
// 開発時のデバッグ情報
print('DEBUG: $variableName'); // リリース前に削除

// エラー情報（本番環境でも必要）
debugPrint('Error: $error');
```

### ブラウザ開発者ツール活用
- Console: エラーメッセージ確認
- Network: Firestoreリクエスト確認
- Application > Storage: キャッシュクリア

---

## 📚 参考情報

### エラー対処フロー
1. エラーメッセージをSelectableTextでコピー
2. ブラウザのコンソールで詳細確認
3. Firebase Consoleでルール・データ確認
4. コードのエラーハンドリング追加

### よくあるエラーと解決方法

**`[cloud_firestore/permission-denied]`**
- Firestoreセキュリティルールを確認
- ユーザー認証状態を確認
- Firebase Consoleでルールをデプロイ

**`[cloud_firestore/failed-precondition] The query requires an index`**
- クエリを簡略化（`orderBy`を削除）
- クライアント側でソート実装
- 必要な場合のみインデックス作成

**`context.mounted` チェック**
- 非同期処理後の`context`使用前に必ずチェック
- ウィジェットがマウント解除されている場合の安全対策

---

## 🎯 このルールの適用

### チェックリスト
- [ ] すべてのエラー表示がSelectableTextになっているか
- [ ] Firestoreクエリに不要な`orderBy`がないか
- [ ] 認証チェックが適切に行われているか
- [ ] try-catchでエラーハンドリングされているか
- [ ] context.mountedチェックが行われているか

### レビュー観点
1. ユーザビリティ: エラーが理解しやすいか
2. パフォーマンス: 不要なインデックスがないか
3. セキュリティ: 認証・認可が適切か
4. 保守性: コードが読みやすいか
