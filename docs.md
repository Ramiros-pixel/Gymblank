# GymSlot - Laporan Phase 0 (Technical Feasibility / Proof of Concept)

Status: KODE DITULIS, BELUM DIEKSEKUSI TERHADAP GOOGLE
Versi dokumen: 2.0
Tanggal: 2026-11-02
Referensi: PRD.md (v2.0), TECHNICAL_DOCUMENTATION.md (v2.0), desain.md (v1.1), anti-slop-main/

---

## 1. Tujuan Phase 0

Phase 0 membuktikan integrasi Google benar-benar berfungsi SEBELUM membangun seluruh
fitur. Berdasarkan TECHNICAL_DOCUMENTATION bagian 15, ada 8 poin yang harus terbukti:

1. Flutter dapat login menggunakan Google (mendapatkan ID token).
2. Google Apps Script dapat menerima request dari Flutter.
3. Backend dapat memvalidasi Google ID token.
4. Backend dapat membaca dan menulis Control Spreadsheet.
5. Owner dapat mengotorisasi akses Google Drive dan Google Sheets.
6. Spreadsheet dapat dibuat di Google Drive milik Owner.
7. Refresh token dapat dikelola secara aman.
8. Apps Script dapat menangani request bersamaan.

Dokumen ini mencatat apa yang sudah ditulis, kendala yang tersisa, dan cara melanjutkan
ke eksekusi nyata.

---

## 2. PHASE 0 REPORT

```
PHASE: 0 - Technical Feasibility
STATUS: KODE DITULIS. BELUM TERBUKTI JALAN (butuh eksekusi interaktif).
```

### IMPLEMENTED

- Project Flutter dibuat dan di-rename menjadi `gym_slot` (folder `gym_slot/`),
  konsisten dengan nama di dokumentasi.
- Struktur theme Flutter ditulis sesuai `desain.md`: AppColors (merah/hitam/putih),
  AppTypography (Barlow Condensed + Inter), AppSpacing, AppTheme.
- Layar login PoC ditulis sesuai desain.md 8.2 (latar hitam, tombol merah Google).
- Client HTTP backend ditulis (`api_client.dart`): kirim action + token di body JSON.
- Service Google Sign-In ditulis (`google_auth_service.dart`) sebagai pembungkus.
- Backend Apps Script ditulis di `gym-slot-backend/`:
  - Manifest (`appsscript.json`) dengan scopes Drive/Sheets dan library OAuth2.
  - Auth PoC: `auth.google`, `auth.me`, `auth.logout` lewat satu router.
  - Validasi Google ID token (`googleAuth.gs`) via tokeninfo.
  - Session aplikasi (`session.gs`) di ScriptProperties.
  - Control Spreadsheet repository (`controlRepository.gs`).
  - Setup script `setup_control.gs` (membuat tab + header, idempotent).
  - User service (`userService.gs`) upsert pengguna dari klaim Google.
  - Util: uuid, dateTime, lock, logger.
  - Stub jujur untuk authorization/tenantResolver (Phase 1) dan gymService/
    googleDriveService (Phase 2), yang melempar NOT_IMPLEMENTED (bukan klaim selesai).

### FILES CREATED

Backend (`gym-slot-backend/`):
- appsscript.json
- src/entry/doGet.gs, doPost.gs
- src/config/constants.gs, settings.gs
- src/core/router.gs, response.gs, errors.gs, validator.gs
- src/auth/googleAuth.gs, session.gs
- src/middleware/authentication.gs, authorization.gs, tenantResolver.gs
- src/services/userService.gs, gymService.gs, googleDriveService.gs
- src/repositories/controlRepository.gs
- src/utils/uuid.gs, dateTime.gs, lock.gs, logger.gs
- scripts/setup_control.gs
- README.md

Flutter (`gym_slot/`):
- lib/main.dart (ganti demo counter jadi GymSlotApp + LoginScreen)
- lib/core/theme/app_colors.dart, app_typography.dart, app_spacing.dart, app_theme.dart
- lib/core/network/api_client.dart
- lib/features/authentication/data/google_auth_service.dart
- lib/features/authentication/presentation/login_screen.dart
- test/widget_test.dart (diperbarui: verifikasi tombol login)

### FILES MODIFIED

- gym_slot/pubspec.yaml (rename ke gym_slot + tambah dependency http, google_sign_in)
- gym_slot/web/manifest.json, web/index.html
- gym_slot/android/app/build.gradle.kts, AndroidManifest.xml,
  src/main/kotlin/com/example/gymslot/MainActivity.kt (rename namespace)
- gym_slot/ios/Runner.xcodeproj/project.pbxproj, ios/Runner/Info.plist (bundle id)
- gym_slot/README.md
- Folder project di-rename: `gymblank/` -> `gym_slot/`

### TESTS EXECUTED

- Tidak ada yang dieksekusi. Flutter belum terinstal di host, dan PoC Google
  (login, OAuth, pembuatan spreadsheet) butuh eksekusi interaktif dari perangkat.

### TEST RESULTS

- Belum ada hasil eksekusi. Kode ditulis agar valid secara sintaks; verifikasi build
  dan eksekusi menunggu toolchain + konfigurasi platform.

### KNOWN ISSUES

- Flutter SDK belum terinstal di host -> build/run belum mungkin.
- Font Barlow Condensed dan Inter belum dibundle di pubspec.yaml (desain.md 4).
- GoogleSignIn butuh konfigurasi platform (Android: SHA-1 di Google Cloud Console;
  iOS: URL scheme; web: client id) yang belum diatur.
- Penyimpanan refresh token di PropertiesService adalah solusi PoC saja (K3).
- Stub gymService/googleDriveService melempar NOT_IMPLEMENTED; itu disengaja.

### SECURITY CONSIDERATIONS

- Tidak ada secret yang ditulis ke source code. OAuth Client ID dan client secret
  dibaca dari Script Properties / --dart-define, tidak di-commit.
- ID token dikirim dalam body JSON, bukan header atau URL (K5).
- Identitas final memakai `sub` Google, bukan email dari klien.
- access token, refresh token, dan session tidak pernah ke Flutter sebagai secret;
  Flutter hanya menerima session_token aplikasi.

### NEXT PHASE

- Eksekusi PoC: setup Google Cloud, konfigurasi platform Flutter, deploy Apps Script,
  uji auth.google end-to-end dari perangkat. Setelah 8 poin terbukti, lanjut Phase 1.

---

## 3. Keputusan yang Sudah Diambil (oleh pemilik proyek)

| # | Keputusan | Dampak |
|---|---|---|
| 1 | Nama project dipakai `gym_slot` (bukan gymblank) | Folder & namespace di-rename |
| 2 | Mode anti-slop `during` | Aturan diterapkan saat menulis |
| 3 | `PropertiesService` disetujui untuk PoC token | Penyimpanan token PoC, bukan produksi |
| 4 | Warna UI samakan merah/hitam/putih (override hijau di PRD 8.1) | Tab Dashboard spreadsheet & app sama-sama merah/hitam/putih |
| 5 | Jalur eksekusi: agent tulis source, pemilik jalankan bagian interaktif | docs.md mencatat cara jalankan |
| 6 | OAuth Client ID diberikan: 639855963221-5drifel0v6bdieuvek4il8qevio7qu75.apps.googleusercontent.com | Dipakai untuk konfigurasi platform |

Catatan: keputusan 4 meng-override PRD 8.1 yang menyebut hijau. Ini disepakati pemilik
dan dicatat agar tidak dianggap perubahan sepihak.

---

## 4. Kendala yang Tersisa

### K1. Toolchain Flutter belum terinstal
- Flutter, Dart, clasp belum ada di host.
- Solusi: install Flutter SDK + clasp. Node v24 sudah tersedia untuk clasp.
- Catatan RAM 2 GB: jangan kompilasi paralel (lihat skill flutter-builds).

### K2. Kepemilikan spreadsheet (Drive Owner vs operator)
- Kode PoC membuat Control Sheet di Drive akun deployer (bukan Owner). Untuk spreadsheet
  gym per Owner, `googleDriveService.gs` masih stub (Phase 2).
- Solusi: OAuth2 library + Drive API `files.create` atas nama Owner + verifikasi `owners`.

### K3. Penyimpanan refresh token (blocker produksi)
- PoC: PropertiesService. Produksi: evaluasi secret store eksternal. Laporkan blocker
  sebelum rilis. Batasi editor script.

### K4. Validasi ID token
- PoC: tokeninfo. Produksi: verifikasi signature JWT (Phase 7).

### K5. Header HTTP tidak tersedia di Apps Script
- Sudah diterapkan: token dibawa di body JSON.

### K6. Booking concurrency
- LockService ditulis (`lock.gs`) tapi belum diuji. Uji beban di Phase 4/7.

### K7. Font belum dibundle
- Barlow Condensed + Inter belum ada di assets. Perlu diunduh saat Phase 1.

---

## 5. Cara Menjalankan PoC (untuk pemilik)

### 5.1 Setup backend
1. Install clasp: `npm i -g @google/clasp@latest`.
2. Buat project Apps Script, push file `gym-slot-backend/`.
3. Jalankan `setupControl()` (setup_control.gs) untuk membuat Control Sheet + tab.
4. Atur Script Properties:
   - `gymslot.google_client_id`
   - `gymslot.google_client_secret` (PoC only)
   - `gymslot.control_spreadsheet_id`
   - `gymslot.web_app_url`
5. Deploy sebagai Web App. Catat deployment ID dan versi.
6. Uji health: GET `?action=health`.

### 5.2 Setup Flutter
1. Install Flutter SDK. Jalankan `flutter pub get` di `gym_slot/`.
2. Konfigurasi Google Sign-In per platform:
   - Android: daftarkan SHA-1 ke OAuth Client ID di Google Cloud Console.
   - iOS: tambahkan reversed client id sebagai URL scheme.
   - Web: tambahkan origin web ke OAuth Client ID.
3. Jalankan dengan dart-define:
   `flutter run --dart-define=GYMSLOT_API_URL=<URL Web App> --dart-define=GYMSLOT_GOOGLE_CLIENT_ID=<client id>`
4. Uji: login Google -> kirim ke auth.google -> terima session_token.

### 5.3 PoC OAuth Drive/Sheets (poin 5-7)
- Ini bagian paling interaktif. Butuh akun Google Owner, otorisasi Drive/Sheets,
  dan verifikasi spreadsheet dibuat di Drive Owner (via `owners`). Belum diimplementasi
  di googleDriveService.gs (stub NOT_IMPLEMENTED) karena milik Phase 2.

---

## 6. Kriteria Sukses Phase 0 (Definition of Done)

Phase 0 BELUM selesai. Menjadi selesai hanya ketika SEMUA poin ini terbukti nyata:

- [ ] Flutter berhasil login Google dan mendapat ID token (poin 1).
- [ ] Apps Script menerima request dari Flutter dan merespons (poin 2).
- [ ] Backend memvalidasi ID token dan menolak token invalid/expired/audience-salah (poin 3).
- [ ] Backend membaca dan menulis Control Spreadsheet (poin 4).
- [ ] Owner mengotorisasi akses Drive/Sheets (poin 5).
- [ ] Spreadsheet dibuat di Drive Owner, diverifikasi via `owners` (poin 6).
- [ ] Refresh token dikelola, keputusan penyimpanan dicatat (poin 7).
- [ ] Request bersamaan ditangani tanpa korupsi data (poin 8).
- [ ] Tidak ada secret di source code yang di-commit.
- [ ] Hasil uji dicatat dalam file catatan uji, bukan dummy.

Jangan lanjut ke Phase 1 dengan klaim palsu.

---

## 7. Pekerjaan yang Belum Dilakukan (jujur)

- Kode belum dieksekusi terhadap Google. Semua PoC auth backend ditulis, bukan dijalankan.
- Flutter belum di-build/run (toolchain belum ada).
- OAuth Drive/Sheets atas nama Owner belum diimplementasi (stub, Phase 2).
- docs.md ini harus diperbarui lagi setelah eksekusi nyata memberikan hasil.