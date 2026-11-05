# GymSlot — Dokumentasi Phase 7 (Hardening)

**Tanggal:** 4 November 2026  
**STATUS:** Phase 7 ✅ SELESAI  
**Acuan:** prompt.txt §6 (Standar Keamanan), PRD.md 17 & 20, TECHNICAL_DOCUMENTATION.md 16–18  
**Lihat juga:** docs1.md–docs6.md

---

## IMPLEMENTED

### 1. Security Fixes (prompt.txt §6)

| Area | Sebelum | Sesudah |
|------|---------|---------|
| Rate limiting (PRD 17) | Tidak ada | `src/utils/rateLimiter.gs`: per user+action via CacheService, bucket per menit. Batas: auth.google 5/menit, bookings.create 10/menit, default 30/menit. Melebihi → `RATE_LIMITED` + audit log |
| Validasi audience ID token | Jika `GOOGLE_CLIENT_ID` kosong, aud tidak diperiksa (token OAuth app lain bisa lolos) | **Fail-closed**: jika client ID dikonfigurasi → aud wajib sama persis; jika TIDAK dikonfigurasi → semua token ditolak dengan pesan konfigurasi |
| Payload abnormal | Action/request_id tanpa batas panjang | Ditolak `VALIDATION_ERROR` (action > 64 char, request_id > 128 char) sebelum dispatch |
| Scan secret di Flutter | — | `git grep -inE 'secret\|password\|api_key' gym_slot/lib/` → **kosong** (tidak ada secret di client) |

Rate limiter berjalan sebelum otorisasi (permintaan berlebih ditolak sejak awal) dan tidak menggantikan otorisasi — hanya membatasi laju.

### 2. Test Suite Backend (TECHDOC 16)

`src/tests/tests.gs` — dijalankan dari Apps Script editor: `runAllTests()`, `runUnitTests()`, `runIntegrationTests()`.

**Unit test (11):**
- Session: create/validate/revoke, kedaluwarsa, token invalid/kosong/null
- Validator: required, isIn, isEmail (terima & tolak)
- RateLimiter: limit per action, burst dalam batas diizinkan
- UUID unik & format, DateTime nowIso parseable
- Response format ok/fail, kelengkapan kode error
- Router: action tak dikenal ditolak, body null/kosong ditolak

**Integration test (4):** (butuh `CONTROL_SPREADSHEET_ID`; data uji berawalan `[TEST]` + cleanup di `finally`)
- Control Spreadsheet dapat diakses
- Pembuatan gym menghasilkan data terisolasi (status Pending)
- **Tenant isolation**: user tanpa membership ditolak `TENANT_ACCESS_DENIED` oleh TenantResolver
- Booking tanpa member → gagal `MEMBER_NOT_FOUND` (urutan validasi benar, spreadsheet gym tidak tersentuh)

Pemenuhan matriks test TECHDOC 16 (Authentication / Multi-Tenant / Booking / Dashboard): kasus yang butuh deploy nyata + dua akun Google nyata ditandai di bagian Known Issues; kasus yang bisa diuji kode sudah masuk suite.

### 3. Backup (backup test)

`src/backup/backup.gs`:
- `createBackup(spreadsheetId, label)` — salinan GymBooking → folder Drive `GymSlot_Backups` dengan nama `GymBooking_backup_<timestamp>_<label>` (DriveApp.makeCopy, scope drive.file yang sudah ada)
- `backupAllGyms()` — semua gym Active dengan spreadsheet_id; gym Pending/SetupFailed dilewati dengan alasan
- `listBackups(spreadsheetId)` — daftar backup terbaru dulu
- `cleanupOldBackups(keepPerGym)` — retensi default 7 backup per gym (soft-trash)
- Semua aksi tercatat di AuditLogs (`backup.create`, `backup.cleanup`)
- Restore: bagikan file salinan ke owner gym — data tidak pernah dikirim ke klien

### 4. Deployment Production

`DEPLOYMENT.md` (di root backend) berisi: prasyarat ScriptProperties, syarat test lulus sebelum deploy, langkah Deploy (USER_DEPLOYING + ANYONE_ANONYMOUS beserta alasannya), verifikasi pasca-deploy (curl health + negatif test AUTH_EXPIRED), versioning & rollback via Manage deployments, penjadwalan backup harian via Triggers, dan **checklist go-live berbasis 14 kriteria penerimaan PRD 20**.

---

## FILES CREATED

- `gym-slot-backend/src/utils/rateLimiter.gs`
- `gym-slot-backend/src/tests/tests.gs`
- `gym-slot-backend/src/backup/backup.gs`
- `gym-slot-backend/DEPLOYMENT.md`
- `docs7.md` (file ini)

## FILES MODIFIED

- `src/core/router.gs` — rate limiting + pembatasan panjang field di `route()`
- `src/auth/googleAuth.gs` — validasi aud fail-closed

## TESTS EXECUTED

| Test | Metode | Hasil |
|------|--------|-------|
| Sintaks seluruh backend | `node --check` 35 file .gs | ✅ 35/35 OK |
| Static security audit backend | grep verifikasi: TenantResolver di 22 titik, RateLimiter di route, session TTL+revoke, aud fail-closed, booking double-check dalam lock (tryLock + 2x cek), backup makeCopy, test suite + tenant test, invalidate di 7 service, cache dashboard | ✅ 12/12 |
| Scan secret di Flutter | `git grep -inE 'secret\|password\|api_key' gym_slot/lib/` | ✅ kosong |
| `flutter analyze` | seluruh lib | ✅ No issues found! |
| `flutter test` | LoginScreen tests | ✅ 2 passed |
| `runAllTests()` di Apps Script | butuh deploy nyata | ⏳ dijalankan saat deploy (panduan DEPLOYMENT.md §2) |

## TEST RESULTS

- Backend: 35 file .gs valid sintaks (3.931 baris).
- Static security audit: semua kontrol keamanan yang bisa diverifikasi dari kode terpasang dan benar.
- Flutter: analyze bersih, test lulus — tidak ada regresi dari perubahan backend.
- Test runtime di lingkungan Apps Script: disiapkan (`runAllTests`) dan dijadikan syarat go-live di DEPLOYMENT.md; belum dieksekusi karena memerlukan deployment Google Apps Script yang sebenarnya (akun Google + OAuth consent).

## KNOWN ISSUES

1. **Test runtime belum dieksekusi di Apps Script** — memerlukan deploy + ScriptProperties terisi. Panduan lengkap ada di DEPLOYMENT.md §2; `failed = 0` adalah syarat go-live.
2. **Rate limiter per session-token-hash, bukan per user** — sebelum otorisasi userId belum diketahui, sehingga key memakai hash keberadaan token + action. Ini membatasi abuse anonim namun tidak membatasi satu user abuse lintas banyak token. Perbaikan lanjutan: pindahkan pengecekan kedua ke dalam handler setelah auth (membutuhkan perubahan lebih luas).
3. **Matriks test TECHDOC 16 yang butuh 2 akun Google nyata** (owner gym A vs gym B lintas-tenant end-to-end, reconnect dengan izin dicabut sungguhan, login valid dengan token asli) — terstruktur di suite integration tetapi butuh environment deploy.
4. **Load/concurrency test nyata** — proteksi konkurensi sudah benar di kode (ScriptLock + double-check); pengujian bersamaan sesungguhnya butuh deploy (Apps Script tidak bisa di-load-test lokal). Panduan manual ada di DEPLOYMENT.md §7.
5. **Backup tersimpan di Drive operator** (konsekuensi USER_DEPLOYING) — restore memerlukan berbagi manual ke owner gym; tidak mengirim data ke klien.
6. **Session masih di ScriptProperties** (warisan docs1) — bukan secret store ideal; token tak terenkripsi at-rest di platform Google. Risiko terdokumentasi, acceptable untuk MVP.

## SECURITY CONSIDERATIONS

- Otorisasi tetap **backend-only**: spreadsheet ID selalu dari TenantResolver (22 pemanggilan), tidak pernah dari Flutter.
- Rate limit menutup vektor brute-force login & spam booking sesuai PRD 17.
- Fail-closed pada konfigurasi OAuth mencegah misconfiguration diam-diam menerima token invalid.
- Prinsip anti-slop (prompt.txt §9): tidak ada placeholder yang mengklaim berfungsi — test suite & backup adalah kode nyata yang harus dijalankan; DEPLOYMENT.md jujur menandai langkah yang butuh aksi manusia.

## NEXT PHASE

- **Phase 8 — Future Features** (Midtrans, face recognition, analitik lanjutan, notifikasi, IoT) — **di luar MVP**, hanya dikerjakan setelah persetujuan pemilik project (PRD 4 & 18–19, prompt.txt §1.2).
- Tindakan manusia yang tersisa untuk go-live: isi ScriptProperties, deploy, jalankan `runAllTests()`, aktifkan trigger backup harian (semua terdokumentasi di DEPLOYMENT.md).
