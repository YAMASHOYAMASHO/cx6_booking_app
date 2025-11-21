# CX6 装置予約システム

研究室での装置予約を管理するWebアプリケーションです。

## 📚 ドキュメント

プロジェクトのドキュメントは `docs/` ディレクトリに整理されています:

### 🏗️ アーキテクチャ
- **[システム概要](docs/architecture/overview.md)**: ハイレベルな概要、技術スタック、ディレクトリ構造。
- **[フロントエンドアーキテクチャ](docs/architecture/frontend.md)**: MVVMパターン、Riverpod、UIデザイン。
- **[バックエンドアーキテクチャ](docs/architecture/backend.md)**: Firebaseサービス、Firestoreスキーマ、セキュリティルール。

### 🛠️ 機能
- **[管理者機能](docs/features/admin.md)**: 管理者向けの装置および予約管理。
- **[お気に入り & テンプレート](docs/features/favorites.md)**: お気に入り装置とマクロ予約テンプレート。
- **[タイムラインビュー](docs/features/timeline.md)**: タイムライン表示の詳細。

### 📖 ガイドライン
- **[セットアップ & デプロイ](docs/guidelines/setup_and_deployment.md)**: インストール、設定、デプロイ手順。
- **[コーディング規約](docs/guidelines/coding_rules.md)**: コーディング規約とベストプラクティス。
- **[データ移行](docs/guidelines/migration.md)**: データ移行の履歴とガイド。

## 🚀 クイックスタート

### 1. 依存関係のインストール
```bash
flutter pub get
```

### 2. ローカルでの実行
```bash
flutter run -d chrome
```

*詳細なセットアップ手順については、[セットアップ & デプロイ](docs/guidelines/setup_and_deployment.md) を参照してください。*


