# プロジェクトクリーンアップ - 削除対象ファイル

## 削除対象ドキュメント（開発完了済み）

以下のファイルは開発過程で作成された一時的なドキュメントです。
機能実装が完了したため、削除して問題ありません。

### セットアップガイド系（完了済み）
- `FIREBASE_SETUP.md` - Firebaseセットアップ手順（完了）
- `FIRESTORE_SETUP.md` - Firestoreセットアップ手順（完了）
- `FIRESTORE_INDEX_GUIDE.md` - インデックスガイド（不要：クライアント側ソート採用）
- `FIRESTORE_RULES_UPDATE.md` - ルール更新手順（完了）
- `FIRESTORE_RULES_DEPLOYMENT.md` - ルールデプロイ手順（完了）
- `FONT_DOWNLOAD_GUIDE.md` - フォントダウンロード手順（完了）
- `FONT_SETUP_COMPLETE.md` - フォントセットアップ完了記録（完了）

### 実装アーキテクチャ系（実装完了）
- `FAVORITE_ARCHITECTURE.md` - お気に入り機能アーキテクチャ（実装完了）
- `EQUIPMENT_TIMELINE_ARCHITECTURE.md` - タイムライン機能アーキテクチャ（実装完了）
- `IMPLEMENTATION.md` - 実装記録（完了）

### マイグレーション・変更記録系（適用済み）
- `DATA_MIGRATION.md` - データマイグレーション手順（完了）
- `COLOR_MIGRATION.md` - カラーマイグレーション記録（完了）
- `ERROR_DISPLAY_IMPROVEMENTS.md` - エラー表示改善記録（完了）
- `CHANGELOG_UI.md` - UI変更ログ（完了）

### その他の一時ファイル
- `fonts/README.md` - フォントフォルダ説明（削除可能）

## 保持するドキュメント

以下のファイルはプロジェクトの重要な情報を含むため保持します：

- `README.md` - プロジェクト全体の説明とセットアップ手順
- `PROJECT_RULES.md` - 開発ルール（最重要）

## 一括削除コマンド

PowerShellで以下のコマンドを実行してください：

```powershell
# プロジェクトルートに移動
cd c:\Users\uttya\myProject\cx6_booking_app

# 一括削除
Remove-Item -Path `
  "ADMIN_FEATURES.md", `
  "COLOR_MIGRATION.md", `
  "FIREBASE_SETUP.md", `
  "FIRESTORE_INDEX_GUIDE.md", `
  "FAVORITE_ARCHITECTURE.md", `
  "ERROR_DISPLAY_IMPROVEMENTS.md", `
  "EQUIPMENT_TIMELINE_ARCHITECTURE.md", `
  "DATA_MIGRATION.md", `
  "FIRESTORE_RULES_DEPLOYMENT.md", `
  "CHANGELOG_UI.md", `
  "IMPLEMENTATION.md", `
  "FONT_SETUP_COMPLETE.md", `
  "FONT_DOWNLOAD_GUIDE.md", `
  "FIRESTORE_SETUP.md", `
  "FIRESTORE_RULES_UPDATE.md", `
  "fonts\README.md" `
  -ErrorAction SilentlyContinue

# 削除確認
Write-Host "削除完了！残りのマークダウンファイル:" -ForegroundColor Green
Get-ChildItem -Path . -Filter "*.md" -Recurse | Select-Object FullName
```

## クリーンアップ後の状態

削除後、プロジェクトルートには以下のマークダウンファイルのみが残ります：

```
cx6_booking_app/
├── README.md                    # プロジェクト説明
├── PROJECT_RULES.md             # 開発ルール
└── ios/Runner/Assets.xcassets/  # iOS関連（システムファイル）
    └── LaunchImage.imageset/README.md
```

クリーンな状態になります！
