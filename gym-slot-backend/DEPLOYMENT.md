# GymSlot Backend — Deployment Production (Phase 7)

Panduan deployment Web App Apps Script ke mode produksi. Ikuti urutan; jangan lewati verifikasi.

## 1. Prasyarat

- [ ] `CONTROL_SPREADSHEET_ID` terisi (ScriptProperties) dan tab lengkap (jalankan `setupControlSpreadsheet()` dari `src/setup/setup_control.gs` sekali).
- [ ] `GOOGLE_CLIENT_ID` dan `GOOGLE_CLIENT_SECRET` terisi (ScriptProperties) — **wajib**: tanpa ini validasi token gagal fail-closed sejak Phase 7.
- [ ] `WEB_APP_URL` terisi setelah deploy pertama.
- [ ] `appsscript.json` sudah berisi scopes: `script.external_request`, `spreadsheets`, `drive.file`, `userinfo.email`.
- [ ] Semua file `.gs` di `src/` tersalin ke project Apps Script (urutan bebas; Apps Script meratakan semua file).

## 2. Jalankan Test Sebelum Deploy

Di Apps Script editor:

```javascript
runAllTests()      // unit + integration
```

Syarat lanjut: `failed = 0`. Jika integration gagal karena kontrol spreadsheet belum diset, lengkapi dulu ScriptProperties.

## 3. Deploy

1. Apps Script Editor → **Deploy → New deployment**
2. Type: **Web app**
3. Description: `v1.0.0-phase7`
4. Execute as: **Me** (USER_DEPLOYING — backend mengakses Control + gym spreadsheets atas nama operator)
5. Who has access: **Anyone** (ANYONE_ANONYMOUS — Flutter tanpa login cookie Google; otorisasi oleh session aplikasi di body, bukan cookie)
6. Deploy → izinkan scopes saat diminta
7. Salin **Web App URL** → simpan ke ScriptProperties `WEB_APP_URL`

> Catatan keamanan: `ANYONE_ANONYMOUS` berarti endpoint publik. Ini sesuai arsitektur (otorisasi per-request di backend); rate limiter + validasi session membatasi penyalahgunaan. Jangan gunakan `MYSELF` untuk produksi karena Flutter tidak bisa memanggilnya.

## 4. Verifikasi Pasca-Deploy

```bash
# Health check (GET, tanpa auth)
curl "https://script.google.com/macros/s/<DEPLOYMENT_ID>/exec?action=health"
# Harap: {"success":true,"service":"gymslot-backend","version":"v1"}

# Action tanpa session harus gagal AUTH_EXPIRED (bukan 200 sukses):
curl -X POST "https://script.google.com/macros/s/<DEPLOYMENT_ID>/exec" \
  -H "Content-Type: application/json" \
  -d '{"action":"gyms.list","version":"v1","request_id":"verify-1","payload":{},"auth":{"session_token":"invalid"}}'
# Harap: {"success":false,"error":{"code":"AUTH_EXPIRED",...}}
```

Verifikasi aplikasi Flutter: `flutter run --dart-define=GYMSLOT_API_URL=<WEB_APP_URL> --dart-define=GYMSLOT_GOOGLE_CLIENT_ID=<client-id>` → login → dashboard.

## 5. Versioning & Rollback

- Setiap rilis buat deployment baru (Deploy → Manage deployments → Edit → New version). Versi lama tetap bisa diakses lewat URL deployment lama — gunakan untuk rollback cepat.
- Catat versi di AuditLogs dengan action `deploy.note` (manual).

## 6. Backup Terjadwal

- Manual (sekali sehari / sebelum migrasi): editor → `runBackupAllGyms()`.
- Otomatis: Apps Script editor → Triggers → Add Trigger → fungsi `runBackupAllGyms` → Time-driven → Daily (pilih jam sepi, mis. 02:00–03:00).
- Retensi: jalankan `BackupService.cleanupOldBackups(7)` di trigger mingguan agar maksimal 7 backup per gym.
- Folder backup: Drive operator `GymSlot_Backups/`. Restore = bagikan file salinan ke owner gym; data tidak dikirim ke klien.

## 7. Checklist Go-Live (dari PRD 20 kriteria penerimaan)

- [ ] Login Google + validasi backend berfungsi di build rilis.
- [ ] Owner dapat mendaftarkan gym; spreadsheet dibuat dengan tab benar.
- [ ] Booking konkurensi: dua member booking slot terakhir bersamaan → tepat satu sukses, satu CAPACITY_FULL.
- [ ] Tenant isolation: user gym A tidak bisa membaca gym B (test `tenant isolation denied` lulus).
- [ ] Attendance tercatat dengan waktu server.
- [ ] Dashboard menampilkan data aktual; cache tak menampilkan angka basi setelah data berubah.
- [ ] `runAllTests()` → failed = 0.
- [ ] Rate limit aktif: 6x login dalam satu menit dengan token salah → RATE_LIMITED.
- [ ] Backup harian berjalan; folder GymSlot_Backups terisi.
- [ ] Tidak ada secret di Flutter (periksa `git grep -iE 'secret|password' gym_slot/lib/` kosong).
