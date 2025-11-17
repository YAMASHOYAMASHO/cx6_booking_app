# Firestore セキュリティルール診断

## 🚨 権限エラーの原因と対策

### 問題
事前登録済みの学籍番号で新規アカウント作成時に `PERMISSION_DENIED` エラーが発生

### 最も可能性が高い原因
Firestoreセキュリティルールが正しく設定されていない

---

## ✅ 確認事項チェックリスト

### 1. Firebase Console でセキュリティルールを確認
1. Firebase Console を開く
2. **Firestore Database** → **ルール** タブ
3. 以下のルールが正しく設定されているか確認

### 2. 必須のセキュリティルール（完全版）

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
      allow read: if isAuthenticated();
      allow create, update, delete: if isAdmin();
    }
    
    // ========== users コレクション ==========
    match /users/{userId} {
      allow read: if isAuthenticated();
      
      // ★★★ 重要：新規ユーザー作成のルール ★★★
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

## 🔧 トラブルシューティング手順

### Step 1: デバッグログを確認
アプリを実行して新規登録を試み、ブラウザのデベロッパーツール（F12）のコンソールで以下のログを確認：

```
🔍 [SignUp] 開始: studentId=..., email=...
📋 [SignUp] Step 1: 事前登録確認中...
📄 [AllowedUserRepo] ドキュメント取得: exists=...
✅ [SignUp] Step 1: 事前登録確認成功
🔐 [SignUp] Step 2: Firebase Auth ユーザー作成中...
✅ [SignUp] Step 2: Firebase Auth ユーザー作成成功 - UID: ...
💾 [SignUp] Step 3: Firestore ユーザー情報保存中...
❌ [SignUp] Step 3: Firestore ユーザー情報保存失敗  ← ここでエラー
```

### Step 2: エラーがStep 3で発生する場合
→ **Firestoreセキュリティルールの問題**

以下を確認：
1. Firebase Console → Firestore Database → ルール
2. 上記の完全版ルールがコピーされているか
3. 「公開」ボタンを押したか
4. ルール構文エラーがないか

### Step 3: allowedUsers の登録状態を確認
Firebase Console → Firestore Database → データタブ

```
allowedUsers
  └── {学籍番号}
       ├── email: "学籍番号@stu.kobe-u.ac.jp"
       ├── registered: false  ← これがfalseか確認
       ├── allowedAt: (timestamp)
       └── note: "..."
```

---

## 🎯 よくある問題と解決策

### 問題1: `isAllowedUser()` 関数が機能しない
**原因**: メールアドレスのフォーマットが想定と異なる

**解決策**: デバッグログで実際のemailを確認
```
💾 [SignUp] Step 3: Firestore ユーザー情報保存中...
   - Email: 123456@stu.kobe-u.ac.jp  ← これを確認
```

### 問題2: `registered` が `true` になっている
**原因**: 既にテスト登録が完了している

**解決策**: 
1. Firebase Console → Firestore → allowedUsers → 該当ドキュメント
2. `registered` を `false` に変更
3. `registeredAt` と `userId` フィールドを削除

### 問題3: セキュリティルールの構文エラー
**確認方法**: Firebase Console のルールエディタでエラー表示を確認

**よくあるミス**:
- セミコロンの位置
- `get()` と `exists()` の使い分け
- `request.resource.data` と `resource.data` の違い

---

## 📝 次のステップ

1. **デバッグログを確認**（ブラウザのF12コンソール）
2. **どのStepでエラーが出るか特定**
3. **Firebase Consoleでセキュリティルールを再確認**
4. **allowedUsersのregisteredフラグを確認**

上記の完全版セキュリティルールをFirebase Consoleにコピー＆ペーストして「公開」してください。
