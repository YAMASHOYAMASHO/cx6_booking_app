# 🔧 Firestore セキュリティルール修正版

## 問題
新規登録時（認証前）に `allowedUsers` コレクションを読み取れないため、事前登録確認が失敗する。

## 解決策
`allowedUsers` の読み取りルールを修正する。

---

## ✅ 修正版 Firestoreセキュリティルール（完全版）

以下をFirebase Console → Firestore Database → ルール にコピー＆ペーストして「公開」してください。

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ヘルパー関数
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
    
    // メールアドレスから学籍番号を抽出して、allowedUsersに存在するか確認
    function isAllowedUser(email) {
      let studentId = email.split('@')[0];
      return exists(/databases/$(database)/documents/allowedUsers/$(studentId));
    }
    
    // allowedUsersのregisteredフラグがfalseか確認
    function isUnregisteredAllowedUser(email) {
      let studentId = email.split('@')[0];
      let allowedUser = get(/databases/$(database)/documents/allowedUsers/$(studentId));
      return allowedUser.data.registered == false;
    }
    
    // ========== allowedUsers コレクション ==========
    match /allowedUsers/{studentId} {
      // ★★★ 修正: 新規登録時（認証前）でも読み取り可能にする ★★★
      // セキュリティ考慮: registeredフラグとemailのみ公開、noteは非公開
      allow read: if true;  // 誰でも読み取り可能（事前登録確認のため）
      
      // 管理者のみ作成・更新・削除可能
      allow create, update, delete: if isAdmin();
    }
    
    // ========== users コレクション ==========
    match /users/{userId} {
      allow read: if isAuthenticated();
      
      // 新規ユーザー作成のルール
      allow create: if isAuthenticated() && 
                     isOwner(userId) &&
                     isAllowedUser(request.resource.data.email) &&
                     isUnregisteredAllowedUser(request.resource.data.email);
      
      allow update: if isAuthenticated() && isOwner(userId);
      allow delete: if isAdmin();
    }
    
    // ========== locations コレクション ==========
    match /locations/{locationId} {
      allow read: if isAuthenticated();
      allow create, update, delete: if isAdmin();
    }
    
    // ========== equipments コレクション ==========
    match /equipments/{equipmentId} {
      allow read: if isAuthenticated();
      allow create, update, delete: if isAdmin();
    }
    
    // ========== reservations コレクション ==========
    match /reservations/{reservationId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && 
                     request.resource.data.userId == request.auth.uid;
      allow update: if isAuthenticated() && 
                     (resource.data.userId == request.auth.uid || isAdmin());
      allow delete: if isAuthenticated() && 
                     (resource.data.userId == request.auth.uid || isAdmin());
    }
    
    // ========== favoriteEquipments コレクション ==========
    match /favoriteEquipments/{favoriteId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && 
                     request.resource.data.userId == request.auth.uid;
      allow update, delete: if isAuthenticated() && 
                             resource.data.userId == request.auth.uid;
    }
    
    // ========== favoriteReservationTemplates コレクション ==========
    match /favoriteReservationTemplates/{templateId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && 
                     request.resource.data.userId == request.auth.uid;
      allow update, delete: if isAuthenticated() && 
                             resource.data.userId == request.auth.uid;
    }
  }
}
```

---

## 🔐 セキュリティに関する注意点

### `allow read: if true;` のリスク

**リスク**: 
- 誰でも `allowedUsers` コレクション全体を読み取れる
- 学籍番号とメールアドレスが外部に漏れる可能性

**対策**:
1. `note` フィールドには機密情報を入れない
2. より厳格なルールに変更する場合は以下を検討：

```javascript
// より安全な代替案（オプション）
match /allowedUsers/{studentId} {
  // 認証済みユーザーのみ読み取り可能
  allow read: if isAuthenticated();
  
  // または、特定のドキュメントのみ読み取り可能
  // allow get: if true;  // 個別取得は許可、一覧取得は不可
  
  allow create, update, delete: if isAdmin();
}
```

### より安全な実装方法（将来的な改善案）

1. **クラウド関数を使用**:
   - 事前登録確認をサーバーサイドで実行
   - クライアントは直接 `allowedUsers` にアクセスしない

2. **Firebase Admin SDKでアカウント作成**:
   - 管理者が Firebase Admin SDK で直接ユーザーを作成
   - 学生はパスワード設定のみ行う

---

## 📝 適用手順

1. **Firebase Console を開く**
   - https://console.firebase.google.com/

2. **プロジェクトを選択**
   - cx6_booking_app

3. **Firestore Database → ルール**

4. **上記のルールをコピー＆ペースト**

5. **「公開」ボタンをクリック**

6. **アプリで新規登録を再試行**

---

## ✅ 確認方法

ログで以下が表示されれば成功：

```
🔍 [SignUp] 開始: studentId=124567, email=124567@stu.kobe-u.ac.jp
📋 [SignUp] Step 1: 事前登録確認中...
🔍 [AllowedUserRepo] checkIfAllowed 開始: studentId=124567
📄 [AllowedUserRepo] ドキュメント取得: exists=true
📋 [AllowedUserRepo] allowedUser取得成功:
   - studentId: 124567
   - email: 124567@stu.kobe-u.ac.jp
   - registered: false
✅ [AllowedUserRepo] 登録可能です
✅ [SignUp] Step 1: 事前登録確認成功
🔐 [SignUp] Step 2: Firebase Auth ユーザー作成中...
```
