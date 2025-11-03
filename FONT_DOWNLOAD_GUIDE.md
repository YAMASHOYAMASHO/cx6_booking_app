# フォントダウンロードガイド

## Noto Sans JP フォントのダウンロード手順

### 方法1: Google Fonts（推奨）

1. 以下のURLにアクセス:
   https://fonts.google.com/noto/specimen/Noto+Sans+JP

2. 右上の「Download family」ボタンをクリック

3. ZIPファイルがダウンロードされるので解凍

4. 解凍したフォルダから以下のファイルを選択:
   - `NotoSansJP-Regular.ttf` (通常)
   - `NotoSansJP-Medium.ttf` (中太)
   - `NotoSansJP-Bold.ttf` (太字)

5. これらのファイルを `fonts/` フォルダにコピー

### 方法2: GitHub（代替）

1. 以下のURLにアクセス:
   https://github.com/googlefonts/noto-cjk/tree/main/Sans/OTF/Japanese

2. 以下のファイルをダウンロード:
   - `NotoSansCJKjp-Regular.otf`
   - `NotoSansCJKjp-Medium.otf`
   - `NotoSansCJKjp-Bold.otf`

3. ファイル名を変更:
   - `NotoSansCJKjp-Regular.otf` → `NotoSansJP-Regular.otf`
   - `NotoSansCJKjp-Medium.otf` → `NotoSansJP-Medium.otf`
   - `NotoSansCJKjp-Bold.otf` → `NotoSansJP-Bold.otf`

4. これらのファイルを `fonts/` フォルダに配置

### 方法3: 直接ダウンロードリンク

以下のコマンドをPowerShellで実行（自動ダウンロード）:

```powershell
# Google Fonts APIから直接ダウンロード
Invoke-WebRequest -Uri "https://fonts.google.com/download?family=Noto%20Sans%20JP" -OutFile "fonts/NotoSansJP.zip"
Expand-Archive -Path "fonts/NotoSansJP.zip" -DestinationPath "fonts/NotoSansJP" -Force
Copy-Item "fonts/NotoSansJP/static/NotoSansJP-Regular.ttf" -Destination "fonts/"
Copy-Item "fonts/NotoSansJP/static/NotoSansJP-Medium.ttf" -Destination "fonts/"
Copy-Item "fonts/NotoSansJP/static/NotoSansJP-Bold.ttf" -Destination "fonts/"
Remove-Item "fonts/NotoSansJP.zip"
Remove-Item "fonts/NotoSansJP" -Recurse
```

## 完了後の確認

`fonts/` フォルダに以下のファイルがあることを確認:
- `NotoSansJP-Regular.ttf` または `NotoSansJP-Regular.otf`
- `NotoSansJP-Medium.ttf` または `NotoSansJP-Medium.otf`
- `NotoSansJP-Bold.ttf` または `NotoSansJP-Bold.ttf`

確認できたら、次のステップに進んでください。
