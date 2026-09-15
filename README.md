# ระบบขอเบิกสวัสดิการ (Welfare Claim)

Flutter Web + Firebase (Auth / Firestore / Storage), deploy อัตโนมัติผ่าน GitHub Actions ไป Firebase Hosting

## โครงสร้าง

- `lib/models/` — `AppUser`, `Claim`
- `lib/services/` — `AuthService`, `ClaimRepository` (submit/approve/reject), `StorageService`, `claim_screening_service.dart` (กติกาตัดสิน reject/forward — **ไม่มีสิทธิ์ approve เอง**)
- `lib/features/auth|user|approver/` — หน้าจอ
- `firestore.rules`, `storage.rules` — จุดบังคับสิทธิ์จริง (เพราะไม่มี backend server แยก)

## ขั้นตอนเชื่อม Firebase (ต้องทำก่อนรันได้จริง)

1. สร้างโปรเจกต์ที่ https://console.firebase.google.com
2. เปิดใช้ **Authentication → Email/Password**, **Firestore**, **Storage**
3. ติดตั้ง CLI แล้ว login:
   ```
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   firebase login
   ```
4. รันจาก root โปรเจกต์นี้ (จะ generate `lib/firebase_options.dart` ทับไฟล์ placeholder):
   ```
   flutterfire configure
   ```
5. Deploy security rules:
   ```
   firebase deploy --only firestore:rules,firestore:indexes,storage
   ```

## สร้างผู้ใช้คนแรก (ไม่มีหน้า sign-up ในแอป — provision โดย admin)

1. Firebase Console → Authentication → Add user (กรอก email/password)
2. Firestore → สร้าง collection `users` → document id = **UID เดียวกับ Authentication user** ด้านบน → ใส่ฟิลด์:
   ```
   name: "สมชาย ใจดี"
   email: "somchai@company.com"
   department: "IT"
   role: "user"            // หรือ "approver" / "admin"
   allowanceTotal: 5000
   allowanceRemaining: 5000
   allowedCategories: ["ค่ารักษาพยาบาล", "ค่าเล่าเรียนบุตร"]
   ```

## GitHub Actions deploy

ต้องเพิ่ม repo secret `FIREBASE_SERVICE_ACCOUNT` (JSON ของ service account ที่มีสิทธิ์ Firebase Hosting Admin — สร้างที่ Project Settings → Service Accounts → Generate new private key) แล้วแก้ `projectId` ใน `.github/workflows/deploy.yml` ให้ตรงกับ Firebase project ID จริง

## รันบนเครื่อง

```
flutter run -d chrome
```

## สิ่งที่ยังไม่ได้ทำ (ขั้นถัดไป)

- การอ่านใบเสร็จจากรูปจริง (ชื่อ/ยอดเงิน/ประเภท) ยังเป็น manual input โดย user — ยังไม่ได้ต่อ OCR/Vision AI เพื่อตรวจสอบว่าใบเสร็จเป็นของ user คนนั้นจริงหรือไม่
- หน้าประวัติ/รายงานสรุปสำหรับ Approver (ดูวงเงินคงเหลือภาพรวมทุกคน)
