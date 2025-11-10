# デプロイメントガイド

本システムを実際の環境にデプロイする際に必要な設定変更を記載します。

## 📝 必須設定項目

### 1. メールドメインの設定

**ファイル**: `lib/src/config/auth_config.dart`

```dart
static const String defaultEmailDomain = 'univ.com';
```

**変更方法**:
- `'univ.com'` の部分を実際の大学のメールドメインに変更してください
- 例: `'university.ac.jp'`、`'example.edu'` など

**影響範囲**:
- 学生が学籍番号のみでログインする際に、このドメインが自動付加されます
- 例: 学籍番号 `123456` → メールアドレス `123456@univ.com`

---

## 🔐 認証システムの仕組み

### ユーザータイプ別のログイン方法

#### 1. 学生ユーザー
- **入力**: 学籍番号のみ（例: `123456`）
- **処理**: 自動的にドメインが付加 → `123456@univ.com`
- **利点**: 学籍番号だけで簡単にログイン可能

#### 2. ゲストユーザー・教員・管理者
- **入力**: フルメールアドレス（例: `guest001@guest.com`、`teacher@staff.univ.com`）
- **処理**: 入力されたメールアドレスをそのまま使用
- **利点**: 異なるドメインのユーザーも登録・ログイン可能

### 判定ロジック

```dart
// 入力値に @ が含まれているかで判定
if (input.contains('@')) {
  // フルメールアドレスとして扱う（ゲスト・教員・管理者）
} else {
  // 学籍番号として扱い、ドメインを付加（学生）
}
```

---

## 👥 ユーザー管理

### 新規ユーザーの登録

#### 学生の場合
1. ログイン画面で「アカウントをお持ちでない方はこちら」をクリック
2. 名前を入力
3. 学籍番号のみを入力（例: `123456`）
4. パスワードを設定
5. 「新規登録」をクリック

#### ゲスト・教員・管理者の場合
1. ログイン画面で「アカウントをお持ちでない方はこちら」をクリック
2. 名前を入力
3. フルメールアドレスを入力（例: `guest@example.com`）
4. パスワードを設定
5. 「新規登録」をクリック

### 管理者権限の付与

管理者権限は、Firebaseコンソールから手動で設定する必要があります:

1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. プロジェクトを選択
3. Firestore Database を開く
4. `users` コレクションから対象ユーザーを選択
5. `isAdmin` フィールドを `true` に変更

---

## 🎨 UIテキストのカスタマイズ

**ファイル**: `lib/src/config/auth_config.dart`

以下のメソッドでログイン画面の表示テキストを変更できます:

```dart
// ログイン画面のラベル
static String getUserIdLabel() {
  return '学籍番号 または メールアドレス';
}

// ヘルプテキスト
static String getUserIdHelpText() {
  return '学生: 学籍番号のみ入力\n'
      'ゲスト・教員: フルメールアドレスを入力';
}

// プレースホルダー（入力例）
static String getUserIdPlaceholder() {
  return '例: 123456 または guest@example.com';
}
```

---

## 🔧 その他の設定ファイル

### Firebase設定
- **Android**: `android/app/google-services.json`
- **iOS**: `ios/Runner/GoogleService-Info.plist`
- **Web**: `web/index.html` 内のFirebase config

これらのファイルは、Firebaseプロジェクトの設定から取得してください。

---

## ✅ デプロイ前チェックリスト

- [ ] `auth_config.dart` のメールドメインを変更
- [ ] Firebase設定ファイルを本番環境用に更新
- [ ] Firebaseコンソールでメール/パスワード認証を有効化
- [ ] テストユーザーでログイン動作を確認
  - [ ] 学籍番号のみでログイン
  - [ ] フルメールアドレスでログイン
- [ ] 管理者ユーザーの`isAdmin`フラグを設定
- [ ] Firestoreのセキュリティルールを確認

---

## 📞 トラブルシューティング

### 学籍番号でログインできない
- `auth_config.dart` のドメイン設定を確認
- Firebase Authentication でユーザーが正しく登録されているか確認
- メールアドレスが `学籍番号@設定したドメイン` の形式になっているか確認

### ゲストユーザーがログインできない
- フルメールアドレスで登録されているか確認
- 入力時に `@` を含めているか確認

### 管理者メニューが表示されない
- Firestoreの該当ユーザーの`isAdmin`フィールドが`true`になっているか確認

---

## 📚 関連ファイル

- **認証設定**: `lib/src/config/auth_config.dart` ⭐ **主要な設定ファイル**
- **ログイン画面**: `lib/src/views/login_page.dart`
- **認証ロジック**: `lib/src/viewmodels/auth_viewmodel.dart`
- **マイページ**: `lib/src/views/my_page.dart`

---

**更新日**: 2025年11月7日
