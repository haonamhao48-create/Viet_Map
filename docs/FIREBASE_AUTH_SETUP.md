# Firebase Auth — Đăng nhập Google

## 1. Bật Google Sign-In trên Firebase Console

1. Mở [Firebase Console](https://console.firebase.google.com/) → project `vietmap-9c90d`
2. **Authentication** → **Sign-in method** → bật **Google**
3. Chọn email hỗ trợ dự án → **Save**

## 2. Tạo user profile trên Firestore

App tự tạo document khi đăng nhập thành công:

```
users/{uid}
  uid
  email
  fullName
  avatarUrl
  role: "user"
  provider: "google"
  createdAt
  lastLoginAt
  updatedAt
```

Deploy rules:

```bash
firebase deploy --only firestore:rules
```

(file: `firestore.rules`)

## 3. Cấu hình Web Client ID (bắt buộc cho Windows/Web)

1. Firebase Console → **Project settings** → app **Web**
2. Copy **Web client ID** (dạng `xxxx.apps.googleusercontent.com`)
3. Tạo file `.env` ở thư mục gốc project (copy từ `.env.example`):

```env
GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID
```

## 4. Android (nếu chạy trên điện thoại)

1. Lấy SHA-1 debug:

```bash
cd android
./gradlew signingReport
```

2. Firebase Console → Project settings → Android app → **Add fingerprint**
3. Tải lại `google-services.json` (phải có `oauth_client`, không được rỗng)
4. Thay file `android/app/google-services.json`

## 5. Chạy app

```bash
flutter pub get
flutter run -d windows
```

Luồng app:

- Chưa đăng nhập → `LoginScreen`
- Đăng nhập Google thành công → tạo/cập nhật `users/{uid}` → vào bản đồ
- Đăng xuất từ sidebar bản đồ
