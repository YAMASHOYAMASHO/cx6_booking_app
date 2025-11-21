# バックエンドアーキテクチャ

## 🔥 Firebaseサービス
バックエンドは完全にFirebase Serverlessサービスに依存しています。

### Authentication (認証)
- **方法**: メール/パスワード。
- **ロジック**:
    - **学生**: 学籍番号でログイン (自動的に `@univ.com` にマッピング)。
    - **教員/ゲスト**: 完全なメールアドレスでログイン。

### Firestore Database
NoSQLドキュメントデータベース。

#### スキーマ
- **users**: ユーザープロファイル。
    - `id`, `name`, `email`, `isAdmin`, `createdAt`
- **locations**: 物理的な場所 (部屋)。
    - `id`, `name`, `description`
- **equipments**: 実験装置。
    - `id`, `name`, `locationId`, `status`, `specifications`, `imageUrl`
- **reservations**: 予約記録。
    - `id`, `equipmentId`, `userId`, `startTime`, `endTime`, `note`
- **favoriteEquipments**: ユーザーのお気に入り装置。
- **favoriteReservationTemplates**: マクロ予約用テンプレート。
- **allowedUsers**: 学生登録用のホワイトリスト。

#### セキュリティルール
データの安全性を確保するために厳格なルールが適用されています。
- **読み取り**: 認証済みユーザーには一般的に許可されます。
- **書き込み**:
    - **Users**: 自分のプロファイルのみ変更可能。
    - **Reservations**: 自分の予約のみ作成/変更可能。
    - **Admin**: すべてのコレクションに対して完全な書き込み権限を持つ。

## 🔒 セキュリティベストプラクティス
1.  **認証チェック**: すべてのデータアクセスには有効な認証トークンが必要です。
2.  **認可**: 管理者アクションは、セキュリティルール内で `users` コレクションの `isAdmin` フラグをチェックすることで検証されます。
3.  **バリデーション**: 基本的なデータバリデーション (データ型、必須フィールドなど) はセキュリティルールによって強制されます。

## 📡 API / データアクセス
データアクセスはFlutterアプリ内の `Repository` パターン (`lib/src/repositories/`) を介して処理されます。
- Firestore SDKを直接使用。
- **クエリ**: 可能な限り複合インデックスを避けるように最適化されています。単純なリストの場合はクライアント側でのソートが推奨されます。
