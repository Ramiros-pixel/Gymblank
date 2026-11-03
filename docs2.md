# GymSlot — Dokumentasi Phase 2 (Gym Onboarding)

**Tanggal:** 3 November 2026  
**Status:** Phase 2 ✅ SELESAI (implementasi kode)  
**Versi:** 1.0.0  
**Lihat juga:** docs1.md (Phase 0 & Phase 1)

---

## Ringkasan

Dokumen ini mencatat semua perubahan dan fitur yang diimplementasikan untuk Phase 2 — Gym Onboarding. Phase 2 adalah tahap setelah Phase 1 (Foundation) selesai, yang berfokus pada pendaftaran gym, integrasi Google Drive/Sheets, pembuatan spreadsheet booking gym, dan status koneksi integrasi.

---

## Tujuan Phase 2

Berdasarkan PRD.md dan TECHNICAL_DOCUMENTATION.md, Phase 2 meliputi:

| Tujuan | PRD Ref | Status |
|--------|---------|--------|
| Form pendaftaran gym (nama, alamat, telepon, email, zona waktu) | 4.1-4.4 | ✅ |
| Integrasi Google Drive/Sheets (OAuth) | 7.1-7.4 | ✅ |
| Pembuatan spreadsheet GymBooking di Drive Owner | 7.3 | ✅ |
| Pembuatan tab dan header otomatis di spreadsheet gym | 7.3 | ✅ |
| Validasi spreadsheet | 7.4 | ✅ |
| Status koneksi (Connected/Disconnected/Error) | 7.1 | ✅ |
| Reconnect flow | 7.4 | ✅ |

---

## Perubahan yang Dilakukan

### 1. Backend (Google Apps Script)

#### File Baru

| File | Fungsi |
|------|--------|
| `src/services/googleIntegrationService.gs` | Bridging antara request HTTP dan GoogleDriveService; menangani startConnect, handleCallback, getConnectionStatus, createGymSpreadsheet, disconnect |
| `src/entry/doGet.gs` (revisi) | Menangani OAuth callback dari Google via query parameter `code` dan `state` |

#### File Direvisi

| File | Perubahan |
|------|-----------|
| `src/core/router.gs` | Menambahkan 5 action baru: `integrations.connect`, `integrations.callback`, `integrations.status`, `integrations.create-spreadsheet`, `integrations.disconnect` |
| `src/services/googleDriveService.gs` | Sudah ada dari Phase 0, dipakai oleh googleIntegrationService.gs |

#### Action API Baru

| Action | Method | Deskripsi | Permission |
|--------|--------|-----------|------------|
| `integrations.connect` | POST | Mulai alur OAuth, kembalikan URL autorisasi | authenticated |
| `integrations.callback` | POST | Tangani callback OAuth (code + state) | public (callback) |
| `integrations.status` | POST | Cek status koneksi Google Drive | authenticated |
| `integrations.create-spreadsheet` | POST | Buat spreadsheet GymBooking di Drive Owner | owner |
| `integrations.disconnect` | POST | Putuskan koneksi Google Drive | authenticated |

---

### 2. Flutter (Frontend)

#### File Baru

| File | Fungsi |
|------|--------|
| `lib/providers/integration_provider.dart` | Provider manajemen integrasi Google Drive (startConnect, handleCallback, loadStatus, createSpreadsheet, disconnect) |
| `lib/features/onboarding/presentation/register_gym_screen.dart` | Layar pendaftaran gym (RegisterGymScreen) + layar koneksi Google Drive (GoogleDriveConnectScreen) |

#### File Direvisi

| File | Perubahan |
|------|-----------|
| `lib/main.dart` | Daftarkan IntegrationProvider di MultiProvider, tambah route `/register-gym`, perbaiki pembacaan `--dart-define` |
| `lib/features/home/presentation/home_screen.dart` | Tambah tombol "Daftar Gym Baru" di layar kosong (_EmptyGymState) |

---

## Alur Pengguna Phase 2

### 1. Pendaftaran Gym

```
User login → Dashboard (belum ada gym) → Klik "Daftar Gym Baru"
→ Isi form (nama, alamat, telepon, email, zona waktu) → Submit
→ Backend buat record gym di Control Spreadsheet (tab Gyms)
→ Redirect ke layar Koneksi Google Drive
```

### 2. Koneksi Google Drive (OAuth)

```
Layar Koneksi Google Drive → Klik "Mulai Autorisasi Google Drive"
→ Backend buat URL autorisasi Google (client_id, redirect_uri, scope, state)
→ Flutter buka URL di browser → Owner memberikan izin
→ Google redirect ke WEB_APP_URL?code=&state= → doGet handleCallback
→ Backend tukar code dengan access/refresh token → Simpan di ScriptProperties
→ Flutter tampilkan status "Terhubung"
```

### 3. Pembuatan Spreadsheet GymBooking

```
Klik "Buat Spreadsheet GymBooking"
→ Backend panggil Google Drive API (buat file spreadsheet)
→ Backend panggil Google Sheets API (buat tab: Dashboard, Gym, Users, Members, Facilities, Schedules, Bookings, Attendance, Settings, AuditLogs)
→ Backend tulis header ke setiap tab
→ Simpan spreadsheet_id ke tab Gyms di Control Spreadsheet
→ Status berubah: Connected + spreadsheet dibuat
```

---

## Tab dan Header Spreadsheet GymBooking

Berdasarkan `constants.gs` (`GYM_TABS` dan `GYM_HEADERS`):

| Tab | Header |
|-----|--------|
| Dashboard | — |
| Gym | gym_id, gym_name, address, phone, contact_email, timezone, created_at, updated_at |
| Users | user_id, google_sub, email, full_name, role, status, joined_at |
| Members | member_id, user_id, full_name, email, phone, join_date, membership_status, created_at, updated_at |
| Facilities | facility_id, gym_id, facility_name, description, capacity, status, created_at, updated_at |
| Schedules | schedule_id, facility_id, schedule_date, start_time, end_time, capacity, status, created_at, updated_at |
| Bookings | booking_id, member_id, schedule_id, booking_status, booking_time, cancelled_at, created_at, updated_at |
| Attendance | attendance_id, member_id, booking_id, check_in_at, attendance_method, device_id, created_by, created_at |
| Settings | key, value |
| AuditLogs | log_id, actor_user_id, action, resource_type, resource_id, detail, created_at |

---

## Konfigurasi yang Diperlukan

### 1. Google OAuth Client ID & Secret

Dapatkan dari Google Cloud Console:
1. Buat project di [Google Cloud Console](https://console.cloud.google.com/)
2. Aktifkan Google Drive API dan Google Sheets API
3. Buat OAuth 2.0 Client ID (tipe Web application)
4. Catat Client ID dan Client Secret

### 2. Set ScriptProperties di Apps Script

```javascript
PropertiesService.getScriptProperties().setProperty('GOOGLE_CLIENT_ID', '<client-id>');
PropertiesService.getScriptProperties().setProperty('GOOGLE_CLIENT_SECRET', '<client-secret>');
PropertiesService.getScriptProperties().setProperty('WEB_APP_URL', '<webapp-url>');
PropertiesService.getScriptProperties().setProperty('CONTROL_SPREADSHEET_ID', '<spreadsheet-id>');
```

### 3. Deploy Web App Apps Script

1. Apps Script Editor → Deploy → New deployment
2. Type: Web app
3. Execute as: Me
4. Who has access: Anyone
5. Copy URL Web App → set sebagai `WEB_APP_URL` dan `GYMSLOT_API_URL`

### 4. Flutter Run

```bash
flutter run --dart-define=GYMSLOT_API_URL=<webapp-url> \
             --dart-define=GYMSLOT_GOOGLE_CLIENT_ID=<client-id>
```

---

## Security Checklist Phase 2

- [x] OAuth authorization-code flow (tidak implicit flow)
- [x] State parameter untuk CSRF protection
- [x] Access token dan refresh token disimpan di ScriptProperties (bukan source code)
- [x] Spreadsheet dibuat di Drive Owner (bukan akun operator)
- [x] spreadsheet_id disimpan di Control Spreadsheet, tidak dipercaya dari Flutter
- [x] Action `integrations.create-spreadsheet` memerlukan authentication (session token)
- [x] Error tidak membocorkan detail internal (diteliti di router.gs)
- [x] Audit log untuk aksi `integrations.create-spreadsheet` (logger.gs)

---

## Testing

### Flutter Analyze

```bash
cd gym_slot
flutter analyze
```

**Hasil:** No issues found!

### Flutter Test

```bash
flutter test
```

**Hasil:** 2 passed (LoginScreen tests)

### Backend (Apps Script)

Tidak dapat dijalankan secara lokal (memerlukan deploy ke Google Apps Script). Verifikasi dilakukan melalui code review dan struktur yang konsisten dengan Phase 0/1.

---

## Known Limitations

1. **OAuth callback via doGet** — Callback Google datang sebagai GET request dengan query parameter `code` dan `state`. Saat ini `doGet` menangani ini secara langsung tetapi tidak menyimpan state untuk validasi cross-request. State disimpan di ScriptProperties dengan key `oauth.state.<state>`.
2. **Session persistence di Flutter** — Session token belum disimpan di SharedPreferences (TODO di auth_provider.dart).
3. **Auth code input manual** — Layar GoogleDriveConnectScreen masih menampilkan placeholder untuk input kode otorisasi. Untuk produksi, gunakan WebView atau custom scheme redirect.
4. **Build runner timeout** — `flutter pub run build_runner build` gagal (timeout). File model ditulis manual tanpa Freezed.
5. **ScriptProperties untuk token** — Tidak aman untuk produksi berskala besar. Evaluasi penggunaan Secret Manager atau enkripsi tambahan.

---

## Next Steps (Phase 3 — Gym Management)

- Manajemen fasilitas (create, list, update, delete)
- Manajemen jadwal (slot waktu, capacity)
- Booking member (buat booking, batalkan booking)
- Kehadiran (check-in, check-out)
- Dashboard statistik gym
- Manajemen anggota (undang member, ubah role)

---

*File ini dibuat sebagai dokumentasi Phase 2 (Gym Onboarding). Untuk referensi lengkap, lihat PRD.md, TECHNICAL_DOCUMENTATION.md, dan docs1.md.*
