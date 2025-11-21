# セットアップ & デプロイ

## 🚀 初回セットアップ

### 1. 依存関係
```bash
flutter pub get
```

### 2. 設定
サンプルファイルから `lib/src/config/auth_config.dart` を作成します。
```bash
# Windows
Copy-Item lib\src\config\auth_config.dart.example lib\src\config\auth_config.dart
```

**`auth_config.dart` の編集**:
- `defaultEmailDomain` を組織のドメイン (例: `univ.ac.jp`) に設定してください。

### 3. Firebaseセットアップ
- Firebaseプロジェクトを作成します。
- **Authentication** (メール/パスワード) を有効にします。
- **Firestore Database** を有効にします。
- 設定ファイル (`google-services.json`, `GoogleService-Info.plist`) をダウンロードし、それぞれのフォルダに配置します。
- Webの場合は、`firebase_options.dart` または `index.html` を更新します。

## 🌍 デプロイ

### Webビルド
```bash
flutter build web --release
```

### ホスティング
Firebase Hostingにデプロイします:
```bash
firebase deploy --only hosting
```

### セキュリティルール
Firestoreルールをデプロイします:
```bash
firebase deploy --only firestore:rules
```
*ルールの詳細については `docs/architecture/backend.md` を参照してください。*
