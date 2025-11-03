# フォントファイルのダウンロードと配置手順

## 📥 ダウンロード手順（推奨）

### 1. Google Fontsからダウンロード

1. **ブラウザで以下のURLを開く:**
   ```
   https://fonts.google.com/noto/specimen/Noto+Sans+JP
   ```

2. **右上の「Download family」ボタンをクリック**
   - `Noto_Sans_JP.zip` がダウンロードされます

3. **ZIPファイルを解凍**
   - ダウンロードフォルダで右クリック → 「すべて展開」

4. **必要なファイルをコピー**
   - 解凍したフォルダ内の `static` フォルダを開く
   - 以下の3つのファイルを探す:
     - `NotoSansJP-Regular.ttf`
     - `NotoSansJP-Medium.ttf`
     - `NotoSansJP-Bold.ttf`
   
5. **プロジェクトのfontsフォルダに配置**
   - これら3つのファイルを以下の場所にコピー:
     ```
     c:\Users\uttya\myProject\cx6_booking_app\fonts\
     ```

## ✅ 配置確認

以下のファイルが存在することを確認:
```
c:\Users\uttya\myProject\cx6_booking_app\fonts\NotoSansJP-Regular.ttf
c:\Users\uttya\myProject\cx6_booking_app\fonts\NotoSansJP-Medium.ttf
c:\Users\uttya\myProject\cx6_booking_app\fonts\NotoSansJP-Bold.ttf
```

## 🔄 次のステップ

ファイルの配置が完了したら、以下のコマンドを実行:

```powershell
flutter pub get
flutter run -d chrome
```

## 💡 代替方法（GitHub経由）

もしGoogle Fontsからダウンロードできない場合:

1. 以下のURLにアクセス:
   ```
   https://github.com/notofonts/noto-cjk/releases
   ```

2. 最新のリリースから `Sans.zip` をダウンロード

3. 解凍して `OTF/Japanese/` フォルダ内の以下のファイルを探す:
   - `NotoSansCJKjp-Regular.otf` → `NotoSansJP-Regular.ttf` にリネーム
   - `NotoSansCJKjp-Medium.otf` → `NotoSansJP-Medium.ttf` にリネーム
   - `NotoSansCJKjp-Bold.otf` → `NotoSansJP-Bold.ttf` にリネーム

4. リネームしたファイルを `fonts/` フォルダに配置

## ⚠️ トラブルシューティング

### エラー: "Unable to load asset"

- ファイル名のスペルが正確か確認
- ファイルが正しい場所にあるか確認
- `flutter clean` してから `flutter pub get` を実行

### フォントが反映されない

1. アプリを完全に停止
2. `flutter clean` を実行
3. `flutter pub get` を実行
4. アプリを再起動
