# ローカルフォント設定完了ガイド

## 📋 現在の状態

以下のファイルを更新しました：

### ✅ 完了した設定
1. **pubspec.yaml** - フォント設定を追加
2. **lib/main.dart** - Google Fontsの代わりにローカルフォント'NotoSansJP'を使用

### ⏳ 必要な作業
フォントファイルを手動でダウンロードして配置してください。

---

## 📥 フォントファイルのダウンロード手順

### 方法1: Google Fonts（推奨・最も簡単）

1. **ブラウザで開く:**
   ```
   https://fonts.google.com/noto/specimen/Noto+Sans+JP
   ```

2. **ダウンロード:**
   - 画面右上の **「Download family」** ボタンをクリック
   - `Noto_Sans_JP.zip` がダウンロードされます

3. **解凍:**
   - ダウンロードした `Noto_Sans_JP.zip` を右クリック
   - 「すべて展開」を選択

4. **ファイルを探す:**
   - 解凍したフォルダ内の **`static`** フォルダを開く
   - 以下の3つのファイルを見つける:
     ```
     NotoSansJP-Regular.ttf  (約 8MB)
     NotoSansJP-Medium.ttf   (約 8MB)
     NotoSansJP-Bold.ttf     (約 8MB)
     ```

5. **プロジェクトに配置:**
   - この3つのファイルをコピー
   - 以下のフォルダに貼り付け:
     ```
     c:\Users\uttya\myProject\cx6_booking_app\fonts\
     ```

---

### 方法2: 直接リンク（Webブラウザで開く）

以下のリンクをブラウザで開いてダウンロード:
- https://fonts.google.com/download?family=Noto%20Sans%20JP

---

## ✅ 配置確認

エクスプローラーで以下の場所を開き、3つのファイルがあることを確認:

```
c:\Users\uttya\myProject\cx6_booking_app\fonts\
├── NotoSansJP-Regular.ttf  ✓
├── NotoSansJP-Medium.ttf   ✓
└── NotoSansJP-Bold.ttf     ✓
```

---

## 🚀 アプリの起動

ファイル配置後、以下のコマンドを実行:

### PowerShellで実行:
```powershell
cd c:\Users\uttya\myProject\cx6_booking_app

# パッケージを更新
flutter pub get

# アプリを起動
flutter run -d chrome
```

---

## 💡 動作確認

アプリ起動後、以下を確認:
- ✅ フォントの読み込みエラーが出ない
- ✅ 日本語がきれいに表示される
- ✅ ページ読み込み時のフォント切り替えがない（FOUC問題が解決）
- ✅ オフラインでも正しく表示される

---

## 🔧 トラブルシューティング

### エラー: "Unable to load asset: fonts/NotoSansJP-Regular.ttf"

**原因:** ファイルが正しく配置されていない

**解決策:**
1. ファイル名が正確か確認（大文字小文字も一致させる）
2. ファイルの拡張子が `.ttf` であることを確認
3. 以下のコマンドで確認:
   ```powershell
   Get-ChildItem fonts\*.ttf
   ```

### フォントが反映されない

**解決策:**
```powershell
# キャッシュをクリア
flutter clean

# パッケージを再取得
flutter pub get

# アプリを再起動
flutter run -d chrome
```

### ファイルサイズが小さすぎる（1MB未満）

**原因:** ダウンロードが不完全

**解決策:**
- ブラウザでダウンロードし直す
- ダウンロード完了まで待つ
- 各ファイルは約8MBあるはずです

---

## 📊 ローカルフォントのメリット

今回の設定により：
- ✅ **高速表示** - ネットワーク不要でフォント即表示
- ✅ **オフライン対応** - インターネットなしでも動作
- ✅ **FOUC問題解決** - フォント切り替えのちらつきなし
- ✅ **安定性向上** - Google Fonts APIの障害に影響されない

---

## 📝 補足情報

### google_fonts パッケージについて

ローカルフォントに切り替えたため、`google_fonts` パッケージは不要になりました。
削除したい場合は以下のコマンドを実行:

```powershell
flutter pub remove google_fonts
```

ただし、将来的に他のフォントを試す可能性がある場合は、そのまま残しておいても問題ありません。

---

## 🎯 次のステップ

1. ✅ フォントファイルをダウンロード（上記手順1-4）
2. ✅ `fonts/` フォルダに配置（上記手順5）
3. ✅ `flutter pub get` を実行
4. ✅ アプリを起動して確認

質問や問題があれば、お気軽にお知らせください！
