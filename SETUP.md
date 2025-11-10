# 初期セットアップガイド

このプロジェクトをクローンした後、以下の手順で初期設定を行ってください。

## 📋 セットアップ手順

### 1. 認証設定ファイルの作成

環境固有の設定ファイルを作成します。

**Windows (PowerShell):**
```powershell
Copy-Item lib\src\config\auth_config.dart.example lib\src\config\auth_config.dart
```

**macOS/Linux:**
```bash
cp lib/src/config/auth_config.dart.example lib/src/config/auth_config.dart
```

### 2. メールドメインの設定

`lib/src/config/auth_config.dart` を開いて、以下の行を編集:

```dart
static const String defaultEmailDomain = 'your-university.ac.jp';  // ← ここを編集
```

**変更例:**
- 開発環境: `'localhost.test'` または `'dev.example.com'`
- 本番環境: `'stu.kobe-u.ac.jp'` など実際の大学ドメイン

### 3. Flutterパッケージのインストール

```bash
flutter pub get
```

### 4. Firebase設定

Firebase Console から設定ファイルを取得して配置:

- **Android**: `android/app/google-services.json`
- **iOS**: `ios/Runner/GoogleService-Info.plist`
- **Web**: `web/index.html` のFirebase設定を更新

### 5. 動作確認

```bash
flutter run
```

---

## 🔄 環境別の設定

### 開発環境
```dart
static const String defaultEmailDomain = 'localhost.test';
```

### ステージング環境
```dart
static const String defaultEmailDomain = 'staging.yourschool.ac.jp';
```

### 本番環境
```dart
static const String defaultEmailDomain = 'stu.yourschool.ac.jp';
```

---

## ⚠️ 注意事項

- `auth_config.dart` は `.gitignore` に登録済みのため、Gitにコミットされません
- 各開発者・各環境で独自の設定を保持できます
- チーム内で設定を共有する場合は、別途安全な方法（Slack、ドキュメントなど）で共有してください

---

## 🆘 トラブルシューティング

### エラー: `auth_config.dart` が見つからない

```
Error: Could not find file 'lib/src/config/auth_config.dart'
```

→ 手順1の「認証設定ファイルの作成」を実行してください

### ログインできない

→ `auth_config.dart` のドメイン設定が、Firebaseに登録されているメールアドレスのドメインと一致しているか確認してください

---

## 📚 関連ドキュメント

- 詳細なデプロイ手順: `DEPLOYMENT_GUIDE.md`
- 設定クイックリファレンス: `CONFIG_SETUP.md`
