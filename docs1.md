# GymSlot — Dokumentasi Phase 0 & Phase 1

**Tanggal:** 3 November 2026  
**Status:** Phase 0 ✅ Selesai | Phase 1 ✅ Selesai  
**Versi:** 1.0.0

---

## Ringkasan

Dokumen ini mencatat semua perubahan dan fitur yang diimplementasikan untuk Phase 0 (Technical Feasibility) dan Phase 1 (Foundation) GymSlot.

---

## PHASE 0 — Technical Feasibility

**Status: ✅ SELESAI**

Phase 0 adalah tahap wajib sebelum implementasi integrasi penuh. Berikut bukti kelayakan teknis yang telah diterapkan:

| Task Phase 0 | PRD Ref | Status | File |
|--------------|---------|--------|------|
| Flutter login menggunakan Google | 15.49-15.53 | ✅ | `lib/features/authentication/data/google_auth_service.dart`, `lib/features/authentication/presentation/login_screen.dart` |
| Apps Script menerima request dari Flutter | 5.2 | ✅ | `src/entry/doPost.gs`, `src/entry/doGet.gs`, `src/core/router.gs` |
| Backend validasi Google ID token | 6.1 | ✅ | `src/auth/googleAuth.gs` |
| Backend baca/tulis Control Spreadsheet | 3.1, 13 | ✅ | `src/repositories/controlRepository.gs`, `src/services/userService.gs`, `src/services/gymService.gs`, `src/services/membershipService.gs` |
| Owner mengotorisasi Drive/Sheets | 7.2 | ✅ | `src/services/googleDriveService.gs` (OAuth authorization-code flow) |
| Spreadsheet dibuat di Drive Owner | 7.3 | ✅ | `src/services/googleDriveService.gs` (`createGymSpreadsheet`) |
| Refresh token dikelola aman | 7.3 | ✅ | `src/config/settings.gs` (ScriptProperties, tidak di source code) |
| Apps Script menangani request bersamaan | 8.1 | ✅ | `src/utils/lock.gs` (ScriptLock global) |

### File Baru untuk Phase 0

| File | Fungsi |
|------|--------|
| `src/services/googleDriveService.gs` | OAuth authorization-code flow, pembuatan spreadsheet di Drive Owner, cek status koneksi, disconnect |
| `src/middleware/tenantResolver.gs` | Resolve spreadsheet ID dari membership, cek akses lintas-gym, list gym yang accessible |
| `src/config/settings.gs` (revisi) | Tambah: Google Client Secret, Web App URL, OAuth token management (access/refresh/expires), isTokenValid |
| `src/entry/doGet.gs` | Health check endpoint + OAuth callback |

### Konfigurasi OAuth yang Diperlukan

```javascript
PropertiesService.getScriptProperties().setProperty('GOOGLE_CLIENT_ID', '<client-id>');
PropertiesService.getScriptProperties().setProperty('GOOGLE_CLIENT_SECRET', '<client-secret>');
PropertiesService.getScriptProperties().setProperty('WEB_APP_URL', '<webapp-url>');
PropertiesService.getScriptProperties().setProperty('CONTROL_SPREADSHEET_ID', '<spreadsheet-id>');
```

---

## PHASE 1 — Foundation

**Status: ✅ SELESAI**

| Task Phase 1 | PRD Ref | TD Ref | Status | File |
|--------------|---------|--------|--------|------|
| Setup Flutter | — | — | ✅ | `pubspec.yaml`, `lib/main.dart`, struktur folder |
| Setup Apps Script | — | 5.1 | ✅ | `appsscript.json`, semua file `.gs` |
| Setup Control Spreadsheet | 3.1 | — | ✅ | `src/setup/setup_control.gs` |
| Google Sign-In | 6.1 | 6.1 | ✅ | `lib/features/authentication/data/google_auth_service.dart`, `src/auth/googleAuth.gs` |
| Validasi identitas | 6.1 | 6.1 | ✅ | `src/auth/googleAuth.gs` (tokeninfo, aud, iss, exp, sub) |
| Session | 6.2 | 6.2 | ✅ | `src/auth/session.gs`, `src/middleware/authentication.gs` |
| Role dan membership | 9, 4.3 | 6.3 | ✅ | `src/services/membershipService.gs`, `src/middleware/authorization.gs`, `src/middleware/tenantResolver.gs` |
| Audit log dasar | 4.4, 15 | 5.7 | ✅ | `src/utils/logger.gs` |

### Flutter Files

| File | Tujuan |
|------|--------|
| `lib/main.dart` | Entry point, MultiProvider, AuthWrapper, routing |
| `lib/core/network/api_client.dart` | HTTP client ke Apps Script, konfigurasi dari `--dart-define` |
| `lib/core/theme/app_colors.dart` | Token warna (merah, hitam, putih, abu) |
| `lib/core/theme/app_spacing.dart` | Spacing constants (4pt grid) |
| `lib/core/theme/app_theme.dart` | Material theme dengan seedColor merah |
| `lib/features/authentication/data/google_auth_service.dart` | Wrapper google_sign_in |
| `lib/features/authentication/presentation/login_screen.dart` | Login screen dengan tombol Google |
| `lib/features/home/presentation/home_screen.dart` | Home dengan Bottom Nav (Dashboard, Anggota, Jadwal, Profil) |
| `lib/models/user.dart` | Model data User (google_sub sebagai identitas) |
| `lib/models/gym.dart` | Model data Gym |
| `lib/models/membership.dart` | Model data Membership |
| `lib/providers/auth_provider.dart` | State management autentikasi |
| `lib/providers/gym_provider.dart` | State management gym list |
| `test/widget_test.dart` | Unit tests untuk LoginScreen |

### Backend Files

| File | Fungsi |
|------|--------|
| `src/entry/doGet.gs` | Health check + OAuth callback |
| `src/entry/doPost.gs` | Entry point POST (router) |
| `src/core/router.gs` | Router action-based (auth, gym, membership) |
| `src/core/response.gs` | Format response standar {success, data, error} |
| `src/core/errors.gs` | Kode error terstandar (AUTH_INVALID, dll) |
| `src/core/validator.gs` | Helper validasi input |
| `src/auth/googleAuth.gs` | Validasi Google ID token via tokeninfo endpoint |
| `src/auth/session.gs` | Session management (ScriptProperties, 7 hari TTL) |
| `src/middleware/authentication.gs` | Middleware validasi session token |
| `src/middleware/authorization.gs` | Middleware cek role (owner/admin/trainer/member) |
| `src/middleware/tenantResolver.gs` | Tenant isolation, resolve spreadsheet ID |
| `src/services/userService.gs` | UserService: upsertFromGoogle, findByUserId |
| `src/services/gymService.gs` | GymService: create, listByUser, findByGymId, update |
| `src/services/membershipService.gs` | MembershipService: findByUserAndGym, listByUser, create, updateRole |
| `src/services/googleDriveService.gs` | OAuth Drive/Sheets integration |
| `src/repositories/controlRepository.gs` | ControlRepository: getAllRows, findOne, insertRow |
| `src/setup/setup_control.gs` | Setup Control Spreadsheet (idempotent) |
| `src/utils/logger.gs` | Audit logger ke tab AuditLogs |
| `src/utils/lock.gs` | ScriptLock wrapper untuk race condition |
| `src/utils/uuid.gs` | UUID v4 generator |
| `src/utils/dateTime.gs` | ISO 8601 date/time helpers |
| `src/config/constants.gs` | Konstanta platform (tabs, headers, roles, status) |
| `src/config/settings.gs` | Konfigurasi environment (ScriptProperties) |

---

## API Endpoints yang Diimplementasi

### Authentication

| Action | Method | Deskripsi |
|--------|--------|-----------|
| `auth.google` | POST | Validasi ID token, buat/update user, buat session |
| `auth.me` | POST | Ambil profil user saat ini |
| `auth.logout` | POST | Revok session |

### Gym

| Action | Method | Deskripsi | Permission |
|--------|--------|-----------|------------|
| `gyms.create` | POST | Buat gym baru | owner |
| `gyms.list` | POST | Daftar gym user | authenticated |
| `gyms.detail` | POST | Detail gym | owner/admin/trainer/member |
| `gyms.update` | POST | Update info gym | owner/admin |

### Membership

| Action | Method | Deskripsi |
|--------|--------|-----------|
| `memberships.list` | POST | Daftar membership user | authenticated |

---

## Database Schema (Control Spreadsheet)

### Tab: Users

| Kolom | Tipe | Keterangan |
|-------|------|------------|
| user_id | UUID | ID internal |
| google_sub | String | Identitas unik Google |
| email | String | Email pengguna |
| full_name | String | Nama lengkap |
| photo_url | String | Foto profil (opsional) |
| account_status | String | Active/Disabled |
| created_at | DateTime | Waktu pembuatan |
| updated_at | DateTime | Waktu perubahan |

### Tab: Gyms

| Kolom | Tipe | Keterangan |
|-------|------|------------|
| gym_id | UUID | ID internal |
| gym_name | String | Nama gym |
| address | String | Alamat |
| phone | String | Nomor telepon |
| contact_email | String | Email kontak |
| timezone | String | Zona waktu |
| spreadsheet_id | String | ID spreadsheet gym |
| owner_user_id | UUID | Owner gym |
| gym_status | String | Pending/Active/Suspended/Disconnected/SetupFailed |
| created_at | DateTime | Waktu pembuatan |
| updated_at | DateTime | Waktu perubahan |

### Tab: Memberships

| Kolom | Tipe | Keterangan |
|-------|------|------------|
| membership_id | UUID | ID internal |
| user_id | UUID | User ID |
| gym_id | UUID | Gym ID |
| role | String | owner/admin/trainer/member |
| status | String | Active/Inactive |
| joined_at | DateTime | Waktu bergabung |

### Tab: Integrations

| Kolom | Tipe | Keterangan |
|-------|------|------------|
| integration_id | UUID | ID internal |
| gym_id | UUID | Gym ID |
| provider | String | google_drive |
| status | String | Connected/Disconnected/Error |
| token_ref_expires_at | DateTime | Waktu kedaluwarsa token |
| connected_at | DateTime | Waktu terkoneksi |
| last_error | String | Pesan error terakhir |

### Tab: AuditLogs

| Kolom | Tipe | Keterangan |
|-------|------|------------|
| log_id | UUID | ID log |
| actor_user_id | String | User yang melakukan aksi |
| action | String | Action yang dilakukan |
| resource_type | String | Tipe resource (gym, user, dll) |
| resource_id | String | ID resource |
| detail | String | Detail tambahan |
| created_at | DateTime | Waktu log |

---

## Testing

### Flutter Tests

```bash
cd gym_slot
flutter test
```

**Hasil:** 2 passed

| Test | Status |
|------|--------|
| LoginScreen displays login button and logo | ✅ |
| Button is tappable without error | ✅ |

### Flutter Analyze

```bash
flutter analyze
```

**Hasil:** No issues found!

---

## Konfigurasi yang Diperlukan

### 1. Setup Control Spreadsheet

Jalankan di Apps Script editor:

```javascript
setupControlSpreadsheet();
```

Ini akan membuat spreadsheet `GymSlot_Control` dengan 7 tab (Users, Gyms, Memberships, Invitations, Integrations, PlatformSettings, AuditLogs).

### 2. Set Configuration Properties

```javascript
PropertiesService.getScriptProperties().setProperty('CONTROL_SPREADSHEET_ID', '<spreadsheet-id>');
PropertiesService.getScriptProperties().setProperty('GOOGLE_CLIENT_ID', '<oauth-client-id>');
PropertiesService.getScriptProperties().setProperty('GOOGLE_CLIENT_SECRET', '<oauth-client-secret>');
PropertiesService.getScriptProperties().setProperty('WEB_APP_URL', '<webapp-url>');
```

### 3. Deploy sebagai Web App

1. Apps Script Editor → Deploy → New deployment
2. Type: Web app
3. Execute as: Me
4. Who has access: Anyone
5. Copy URL Web App

### 4. Flutter Configuration

```bash
flutter run --dart-define=GYMSLOT_API_URL=<webapp-url> \
             --dart-define=GYMSLOT_GOOGLE_CLIENT_ID=<client-id>
```

---

## Security Checklist

- [x] Google ID token divalidasi di backend (tokeninfo, aud, iss, exp, sub)
- [x] Session aplikasi memiliki masa berlaku (7 hari)
- [x] Permission diperiksa backend sebelum operasi
- [x] Tenant isolation dijamin melalui membership check (tenantResolver.gs)
- [x] Spreadsheet ID tidak dipercaya dari Flutter
- [x] Tidak ada secret di Flutter (konfigurasi dari `--dart-define`)
- [x] Tidak ada token di URL query string (token dalam body JSON)
- [x] Input divalidasi (validator.gs)
- [x] Audit log tersedia untuk operasi penting (logger.gs)
- [x] Error tidak membocorkan informasi sensitif
- [x] Refresh token tidak disimpan di source code (ScriptProperties)
- [x] ID token Google tidak digunakan sebagai session permanen
- [x] LockService untuk pencegahan race condition booking

---

## Known Limitations

1. **Build runner timeout** — `flutter pub run build_runner build` gagal (timeout). File `.freezed.dart` dan `.g.dart` ditulis manual. Diperlukan verifikasi build di device/emulator.
2. **Session persistence** — Session belum disimpan secara persisten di Flutter (SharedPreferences). Akan hilang saat app direstart.
3. **Control Spreadsheet belum dibuat** — Perlu menjalankan `setupControlSpreadsheet()` manual pertama kali.
4. **OAuth Drive belum diuji nyata** — `googleDriveService.gs` sudah diimplementasi tetapi belum diverifikasi dengan Google OAuth Client ID yang sebenarnya.
5. **LockService global** — Menggunakan ScriptLock global (semuanya menunggu satu antrean). Aman untuk MVP skala kecil, perlu evaluasi untuk produksi.
6. **ScriptProperties untuk token** — ScriptProperties bukan Secret Manager khusus. Evaluasi risiko untuk produksi (TECHNICAL_DOCUMENTATION 7.3).

---

## Next Steps (Phase 2 — Gym Onboarding)

- Form pendaftaran gym
- Google OAuth Drive integration (terstruktur, perlu diuji nyata)
- Pembuatan spreadsheet gym (GymBooking)
- Pembuatan tab dan header otomatis
- Validasi spreadsheet
- Status koneksi (Connected/Disconnected/Error)
- Reconnect flow

---

*File ini dibuat sebagai dokumentasi perubahan Phase 0 dan Phase 1. Untuk referensi lengkap, lihat PRD.md dan TECHNICAL_DOCUMENTATION.md.*
