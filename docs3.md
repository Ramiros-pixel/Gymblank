# GymSlot — Dokumentasi Phase 3 (Gym Management)

**Tanggal:** 4 November 2026  
**Status:** Phase 3 ✅ SELESAI (implementasi + verifikasi)  
**Versi:** 1.0.0  
**Lihat juga:** docs1.md (Phase 0 & 1), docs2.md (Phase 2)

---

## Ringkasan

Dokumen ini mencatat semua perubahan dan fitur yang diimplementasikan untuk Phase 3 — Gym Management: manajemen anggota, fasilitas, dan jadwal, sesuai PRD.md bagian 9–12 dan TECHNICAL_DOCUMENTATION.md bagian 4.5–4.7.

---

## Fitur Baru Phase 3

| Fitur | PRD Ref | Status | Keterangan |
|-------|---------|--------|------------|
| Manajemen anggota (CRUD + soft delete) | 10 | ✅ | Tab Members di spreadsheet gym |
| Manajemen fasilitas (CRUD + soft delete) | 11 | ✅ | Tab Facilities, status Active/Inactive/Maintenance |
| Manajemen jadwal (CRUD + deteksi tabrakan) | 12 | ✅ | Tab Schedules, cegah jadwal bertabrakan per fasilitas |
| Role-based access per action | 9 | ✅ | List untuk semua role, tulis hanya staff (owner/admin/trainer) |
| Audit log operasional per gym | — | ✅ | Ditulis ke tab AuditLogs spreadsheet gym |

---

## Perubahan Backend (Google Apps Script)

### File Baru

| File | Fungsi |
|------|--------|
| `src/repositories/gymRepository.gs` | Repository untuk tab operasional di spreadsheet GymBooking per-gym: getAllRows, findOne, insertRow, updateRow (dengan updated_at otomatis), audit. Kunci tenant isolation — hanya menerima spreadsheet ID dari metadata backend |
| `src/services/memberService.gs` | Manajemen anggota: findAll, findByMemberId, findByUserId, create (cek duplikat), update, deactivate |
| `src/services/facilityService.gs` | Manajemen fasilitas: findAll, findByFacilityId, create, update, deactivate |
| `src/services/scheduleService.gs` | Manajemen jadwal: findAll, findByScheduleId, findByFacilityAndDate, hasConflict (overlap interval), create (validasi fasilitas aktif + tabrakan), update (validasi ulang tabrakan), deactivate |

### File Direvisi

| File | Perubahan |
|------|-----------|
| `src/core/router.gs` | +12 action baru (members.*, facilities.*, schedules.*). Semua handler melakukan resolusi spreadsheet via TenantResolver.resolveSpreadsheetId — spreadsheet ID tidak pernah diterima dari Flutter (TD 17) |
| `src/core/errors.gs` | +4 kode error: MEMBER_NOT_FOUND, FACILITY_NOT_FOUND, SCHEDULE_NOT_FOUND, SCHEDULE_CONFLICT |

### Action API Baru

| Action | Permission | Deskripsi |
|--------|-----------|-----------|
| `members.list` | owner/admin/trainer/member | Daftar anggota gym |
| `members.create` | owner/admin/trainer | Tambah anggota (cek duplikat per gym) |
| `members.update` | owner/admin/trainer | Edit anggota (nama, email, telepon, status) |
| `members.deactivate` | owner/admin/trainer | Nonaktifkan anggota |
| `facilities.list` | owner/admin/trainer/member | Daftar fasilitas |
| `facilities.create` | owner/admin/trainer | Tambah fasilitas |
| `facilities.update` | owner/admin/trainer | Edit fasilitas |
| `facilities.deactivate` | owner/admin/trainer | Nonaktifkan fasilitas |
| `schedules.list` | owner/admin/trainer/member | Daftar jadwal |
| `schedules.create` | owner/admin/trainer | Buat jadwal (tolak jika bentrok) |
| `schedules.update` | owner/admin/trainer | Edit jadwal (validasi ulang bentrok) |
| `schedules.deactivate` | owner/admin/trainer | Nonaktifkan jadwal |

### Aturan Bisnis yang Diterapkan

1. **Tenant isolation** — setiap request: session → membership check → spreadsheet ID dari metadata backend → operasi hanya pada spreadsheet gym yang sah (PRD 17, langkah 1–6).
2. **Deteksi tabrakan jadwal** — overlap interval `[start1, end1)` vs `[start2, end2)` pada fasilitas + tanggal yang sama: `start1 < end2 && end1 > start2`. Berlaku saat create dan update.
3. **Fasilitas non-aktif** tidak bisa menerima jadwal baru.
4. **end_time > start_time** divalidasi di backend.
5. **Soft delete** — anggota jadi `membership_status: Inactive`, fasilitas/jadwal jadi `status: Inactive` (data tidak dihapus fisik).
6. **Audit log per gym** — setiap operasi tulis dicatat ke tab AuditLogs spreadsheet gym (bukan Control Spreadsheet).

---

## Perubahan Flutter (Frontend)

### File Baru

| File | Fungsi |
|------|--------|
| `lib/models/member.dart` | Model Member (member_id, user_id, full_name, email, phone, join_date, membership_status) |
| `lib/models/facility.dart` | Model Facility (facility_id, facility_name, description, capacity, status) |
| `lib/models/schedule.dart` | Model Schedule (schedule_id, facility_id, schedule_date, start/end_time, capacity, status) |
| `lib/providers/management_provider.dart` | State management gabungan untuk anggota/fasilitas/jadwal: load, create, update, deactivate untuk ketiganya |
| `lib/features/management/presentation/gym_detail_screen.dart` | Layar detail gym dengan SegmentedButton 3 tab (Anggota/Fasilitas/Jadwal), list + dialog tambah/edit, FAB, empty state, status chip |

### File Direvisi

| File | Perubahan |
|------|-----------|
| `lib/core/network/api_client.dart` | +class `SessionTokenHolder` (static token). ApiClient otomatis menyertakan token dari holder jika parameter sessionToken tidak diberikan |
| `lib/providers/auth_provider.dart` | Set `SessionTokenHolder.token` saat login, hapus saat logout |
| `lib/main.dart` | Daftarkan ManagementProvider di MultiProvider |
| `lib/features/home/presentation/home_screen.dart` | Kartu gym di dashboard kini membuka GymDetailScreen (sebelumnya TODO kosong) |

### Bug yang Diperbaiki (program jalan tapi berhenti)

1. **`GymProvider.loadGyms()` tidak pernah mengirim session token** — payload `gyms.list` selalu terkirim tanpa `session_token`, sehingga backend membalas `AUTH_EXPIRED` dan daftar gym tidak pernah muncul. Fix: `SessionTokenHolder` diisi AuthProvider saat login dan dibaca ApiClient untuk semua request.
2. **Navigasi kartu gym kosong** — onTap di `_GymCard` hanya TODO komentar; kini membuka GymDetailScreen.

---

## Cek Program yang Sudah Jalan (Server)

Sesuai permintaan, service yang berjalan di server diperiksa:

| Service | Status |
|---------|--------|
| Port 3000 (funnel root, docker-proxy) | ✅ HTTP 200 |
| Port 8099 (srv-monitoring, gunicorn) | ✅ HTTP 200 ( lambat merespons pada timeout 5 dtk, normal pada 20 dtk) |
| Container Docker: huawei-backend, huawei-db, mqtt-golang-frontend/backend/db | ✅ Up 3 months |

Tidak ada service yang berhenti.

---

## Verifikasi Tanpa Error

| Pemeriksaan | Hasil |
|-------------|-------|
| `flutter analyze` | ✅ No issues found! |
| `flutter test` | ✅ 2 passed (All tests passed) |
| `node --check` 27 file .gs backend | ✅ Semua OK (sintaks valid) |
| Kode error baru terdaftar di router mapErrorCode | ✅ MEMBER/FACILITY/SCHEDULE_NOT_FOUND, SCHEDULE_CONFLICT |

---

## Alur Pengguna Phase 3

```
Login → Dashboard → pilih gym → GymDetailScreen
  ├── Tab Anggota: lihat / tambah / edit / nonaktifkan anggota
  ├── Tab Fasilitas: lihat / tambah / edit / nonaktifkan fasilitas
  └── Tab Jadwal: lihat / buat / edit jadwal (backend menolak jika bentrok)
```

---

## Known Limitations

1. **UI form jadwal masih input teks** — tanggal dan jam diisi manual (YYYY-MM-DD, HH:MM). Belum ada date/time picker.
2. **Belum ada UI hapus permanen** — hanya nonaktifkan (soft delete), sesuai keamanan data.
3. **Anggota ditambahkan dengan user_id manual** — mekanisme undangan email (PRD 9) baru tersedia di skema Control (tab Invitations), belum diimplementasi alurnya.
4. **hasConflict membaca seluruh tab Schedules** — untuk MVP skala kecil OK; untuk skala besar perlu optimasi baca per-tanggal.
5. **Session masih in-memory** — SessionTokenHolder belum persisten (SharedPreferences); token hilang saat app restart.

---

## Next Steps (Phase 4 — Booking & Attendance)

- Booking jadwal oleh member (validasi keanggotaan aktif, status jadwal, kapasitas, duplikat)
- Pencegahan overbooking dengan LockService (ScriptLock) + validasi ulang kapasitas di dalam lock (PRD 13 langkah 6–7)
- Pembatalan booking
- Pencatatan kehadiran (check-in dengan waktu server, bukan waktu perangkat)
- Pengaturan attendance (device mode, booking policy, manual attendance)

---

*File ini dibuat sebagai dokumentasi Phase 3 (Gym Management). Untuk referensi lengkap, lihat PRD.md, TECHNICAL_DOCUMENTATION.md, docs1.md, dan docs2.md.*
