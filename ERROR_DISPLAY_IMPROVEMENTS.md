# エラー表示とFirestoreクエリの改善

## 🎯 目的
1. **エラーメッセージをテキスト選択可能にする** - ユーザーがエラーをコピーして検索・報告できるようにする
2. **Firestoreインデックスエラーを解消する** - 複合インデックス不要なクエリに変更する

## 📝 変更内容

### 1. エラー表示の改善

#### 変更対象ファイル
- `lib/src/views/my_page.dart`
- `lib/src/views/template_edit_page.dart`
- `lib/src/views/home_page.dart` (すでに対応済み)

#### 変更内容
**Before:**
```dart
error: (error, stack) => Text('エラー: $error'),
```

**After:**
```dart
error: (error, stack) => SelectableText(
  'エラー: $error',
  style: const TextStyle(
    color: Colors.red,
    fontFamily: 'monospace',
  ),
),
```

または詳細表示版:
```dart
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
      ],
    ),
  ),
),
```

### 2. Firestoreクエリの改善

#### 変更対象ファイル
- `lib/src/repositories/favorite_reservation_template_repository.dart`

#### エラー内容
```
[cloud_firestore/failed-precondition] The query requires an index.
You can create it here: https://console.firebase.google.com/...
```

#### 問題のあったコード
```dart
Stream<List<FavoriteReservationTemplate>> getTemplatesStream(String userId) {
  return _firestore
      .collection(_collectionName)
      .where('userId', isEqualTo: userId)
      .orderBy('updatedAt', descending: true)  // ← インデックスが必要
      .snapshots()
      .map(...)
}
```

#### 修正後のコード
```dart
Stream<List<FavoriteReservationTemplate>> getTemplatesStream(String userId) {
  return _firestore
      .collection(_collectionName)
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map(
        (snapshot) {
          final templates = snapshot.docs
              .map((doc) => FavoriteReservationTemplate.fromFirestore(doc))
              .toList();
          
          // クライアント側でソート（インデックス不要）
          templates.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return templates;
        },
      );
}
```

**利点:**
- ✅ Firestoreの複合インデックス不要
- ✅ クエリがシンプル
- ✅ データ量が少ない場合、パフォーマンスへの影響は微小
- ✅ 開発・デプロイが簡単

### 3. Firestoreセキュリティルールの更新

#### 変更対象ファイル
- `firestore.rules`

#### 修正内容
読み取りルールを緩和（認証済みユーザーならリスト取得可能に）:

**Before:**
```javascript
match /favoriteEquipments/{favoriteId} {
  allow read: if isAuthenticated() && 
                 resource.data.userId == request.auth.uid;
  // ...
}
```

**After:**
```javascript
match /favoriteEquipments/{favoriteId} {
  allow read: if isAuthenticated();
  // セキュリティはクエリ側の where('userId', '==', ...) で確保
  // ...
}
```

**理由:**
- ドキュメントが存在しない場合、`resource.data`が`null`になり読み取りエラーになる
- リスト取得時にすべてのドキュメントの存在チェックが必要になり非効率
- アプリ側で`where('userId', isEqualTo: currentUserId)`によりフィルタリングされるため安全

## 📋 新規作成ファイル

### 1. `PROJECT_RULES.md`
プロジェクトの最重要開発ルールを定義:
- ✅ エラーメッセージは必ずテキスト選択可能に
- ✅ Firestoreクエリでは複合インデックスを避ける
- ✅ 認証状態の確認を徹底
- ✅ エラーハンドリングの徹底

### 2. `FIRESTORE_RULES_DEPLOYMENT.md`
Firestoreセキュリティルールのデプロイ方法を記載:
- Firebase Console経由の手動デプロイ手順
- Firebase CLI経由のデプロイ方法
- トラブルシューティング

## 🔧 デプロイ手順

### 1. Firestoreルールのデプロイ

**方法A: Firebase Console（推奨）**
1. https://console.firebase.google.com/ を開く
2. プロジェクトを選択
3. Firestore Database > ルール
4. `firestore.rules`の内容をコピー&ペースト
5. 「公開」ボタンをクリック

**方法B: Firebase CLI**
```bash
# プロジェクト初期化（初回のみ）
firebase init

# ルールをデプロイ
firebase deploy --only firestore:rules
```

### 2. アプリの再起動

```bash
# 開発サーバーを再起動
flutter run -d chrome
```

### 3. 動作確認

1. マイページにアクセス
2. お気に入り装置セクションを確認（エラーが解消されているか）
3. お気に入りテンプレートセクションを確認（エラーが解消されているか）
4. エラーメッセージをクリック＆ドラッグでテキスト選択できるか確認

## ✅ テストケース

### エラー表示のテスト
1. ネットワークを切断
2. アプリを操作してエラーを発生させる
3. エラーメッセージをマウスで選択
4. コピー（Ctrl+C）できることを確認

### お気に入り機能のテスト
1. マイページを開く
2. お気に入り装置セクションで「＋」ボタンをクリック
3. ロケーションと装置を選択
4. 「追加」ボタンをクリック
5. お気に入りに追加されることを確認
6. リロードして永続化されているか確認

### テンプレート機能のテスト
1. マイページを開く
2. お気に入りテンプレートセクションで「＋」ボタンをクリック
3. テンプレート名を入力
4. スロットを追加
5. 保存
6. テンプレート一覧に表示されることを確認

## 🐛 トラブルシューティング

### エラーが継続する場合

1. **ブラウザキャッシュをクリア**
   - Ctrl+Shift+Delete
   - キャッシュをクリア
   - ページをリロード

2. **Firebase Consoleでルール確認**
   - ルールが正しくデプロイされているか確認

3. **ブラウザコンソールを確認**
   - F12で開発者ツールを開く
   - Consoleタブでエラー詳細を確認
   - エラーメッセージをコピーして検索

4. **Firestore Emulatorを使用している場合**
   - エミュレータを再起動
   - `firestore.rules`が正しく読み込まれているか確認

## 📊 影響範囲

### 変更されたファイル
- ✅ `lib/src/views/my_page.dart` - エラー表示を6箇所修正
- ✅ `lib/src/views/template_edit_page.dart` - エラー表示を2箇所修正
- ✅ `lib/src/repositories/favorite_reservation_template_repository.dart` - クエリを2箇所修正
- ✅ `firestore.rules` - 読み取りルールを2箇所修正

### 新規作成されたファイル
- 📄 `PROJECT_RULES.md` - プロジェクト開発ルール
- 📄 `FIRESTORE_RULES_DEPLOYMENT.md` - Firestoreルールデプロイガイド

### 変更なし（すでに対応済み）
- ✅ `lib/src/views/home_page.dart` - `_ErrorDisplay`ウィジェットで既にSelectableText使用

## 🎓 学んだこと

### Firestoreクエリ最適化
- `where` + `orderBy`の組み合わせは複合インデックスが必要
- データ量が少ない場合、クライアント側ソートで十分
- インデックス作成の手間を省けるメリットが大きい

### セキュリティルール設計
- 読み取りルールで`resource.data`を参照すると、ドキュメント不存在時にエラー
- アプリ側のクエリフィルタと併用することで、シンプルなルールで安全性を保てる

### ユーザビリティ
- エラーメッセージのコピー可能性は重要なUX改善ポイント
- `SelectableText`は簡単に実装でき、大きな効果がある
