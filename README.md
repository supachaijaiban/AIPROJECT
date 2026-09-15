# ระบบขอเบิกสวัสดิการ (Welfare Claim)

Flutter Web + Supabase (Auth / Postgres / Storage), deploy อัตโนมัติผ่าน GitHub Actions ไป **GitHub Pages**

## โครงสร้าง

- `lib/models/` — `AppUser`, `Claim`
- `lib/services/` — `AuthService`, `ClaimRepository` (submit/approve/reject), `StorageService`, `claim_screening_service.dart` (กติกาตัดสิน reject/forward — **ไม่มีสิทธิ์ approve เอง**)
- `lib/features/auth|user|approver/` — หน้าจอ
- `supabase/schema.sql` — ตาราง, Row Level Security, และ RPC (`approve_claim`, `reject_claim`) ซึ่งเป็นจุดบังคับสิทธิ์จริง (เพราะไม่มี backend server แยก)

## ขั้นตอนเชื่อม Supabase (ต้องทำก่อนรันได้จริง)

1. สร้างโปรเจกต์ที่ https://supabase.com/dashboard (ฟรี ไม่ต้องผูกบัตร)
2. เปิด **SQL Editor** → New query → วางเนื้อหาทั้งหมดจาก `supabase/schema.sql` แล้ว Run (สร้างตาราง, RLS, RPC, storage bucket ให้ครบในครั้งเดียว)
3. เปิด **Authentication → Providers** เช็คว่า Email เปิดอยู่ (ค่าเริ่มต้นเปิดอยู่แล้ว)
4. ไปที่ **Project Settings → API** copy `Project URL` และ `anon / publishable key` มาใส่ใน `lib/supabase_config.dart` แทนค่า `REPLACE_ME` ทั้งสองบรรทัด

## สร้างผู้ใช้คนแรก (ไม่มีหน้า sign-up ในแอป — provision โดย admin)

1. Supabase Dashboard → **Authentication → Users → Add user** (กรอก email/password)
2. **Table Editor → profiles → Insert row** → `id` = UID เดียวกับ Authentication user ด้านบน (copy จากหน้า Users) → กรอก:
   ```
   name: "สมชาย ใจดี"
   email: "somchai@company.com"
   department: "IT"
   role: "user"            // หรือ "approver" / "admin"
   allowance_total: 5000
   allowance_remaining: 5000
   allowed_categories: {"ค่ารักษาพยาบาล","ค่าเล่าเรียนบุตร"}
   ```

## Hosting: GitHub Actions → GitHub Pages

ครั้งแรกต้องเปิดใช้งานเอง (ทำครั้งเดียว): repo → **Settings → Pages → Build and deployment → Source** เลือก **GitHub Actions** จากนั้น push ขึ้น `main` แล้วรอ workflow รันจบ เว็บจะขึ้นที่ `https://supachaijaiban.github.io/AIPROJECT/`

Firebase project (`ai-welfare-process-8f83f`) ยังอยู่แต่ไม่ได้ใช้งานแล้ว (ไม่มีค่าใช้จ่ายถ้าไม่ใช้) — ลบทิ้งได้ถ้าไม่ต้องการเก็บไว้

## รันบนเครื่อง

```
flutter run -d chrome
```

## สิ่งที่ยังไม่ได้ทำ (ขั้นถัดไป)

- การอ่านใบเสร็จจากรูปจริง (ชื่อ/ยอดเงิน/ประเภท) ยังเป็น manual input โดย user — ยังไม่ได้ต่อ OCR/Vision AI เพื่อตรวจสอบว่าใบเสร็จเป็นของ user คนนั้นจริงหรือไม่
- หน้าประวัติ/รายงานสรุปสำหรับ Approver (ดูวงเงินคงเหลือภาพรวมทุกคน)
