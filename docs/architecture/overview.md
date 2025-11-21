# システム概要

## 🎯 目的
CX6装置予約システムは、研究室の装置予約を効率的に管理するためのWebアプリケーションです。学生やスタッフが装置の空き状況を確認し、予約を行い、管理することができます。

## 🏗️ アーキテクチャ
本システムは **Model-View-ViewModel (MVVM)** アーキテクチャを採用しており、UI、ビジネスロジック、データアクセス層の関心事を明確に分離しています。

### 技術スタック
- **フロントエンド**: Flutter (Web)
- **バックエンド**: Firebase (BaaS)
    - **Authentication**: ユーザー認証 (メール/パスワード)
    - **Firestore**: ユーザー、装置、予約などを保存するNoSQLデータベース
    - **Storage**: (オプション) 装置画像の保存
    - **Hosting**: Webアプリケーションのデプロイ
- **状態管理**: Riverpod
- **言語**: Dart

## 📂 ディレクトリ構造

```
lib/
├── main.dart                      # アプリケーションのエントリーポイント
└── src/
    ├── config/                    # 設定ファイル (Firebase, Authなど)
    ├── models/                    # ドメインモデル (User, Equipment, Reservation)
    ├── repositories/              # データアクセス層 (Firestoreとのやり取り)
    ├── viewmodels/                # ビジネスロジック & 状態管理 (Riverpod)
    ├── views/                     # UIコンポーネントとページ
    └── utils/                     # ヘルパー関数と定数
```

## 🔄 コアデータフロー
1.  **ユーザーアクション**: ユーザーが **View** (UI) を操作します。
2.  **状態更新**: Viewが **ViewModel** のメソッドを呼び出します。
3.  **データ操作**: ViewModelが **Repository** と対話します。
4.  **データベース**: Repositoryが **Firestore** に対してCRUD操作を実行します。
5.  **リアクティブ更新**: FirestoreがStreamを通じて Repository -> ViewModel -> View へ更新をプッシュし、UIを自動的に更新します。
