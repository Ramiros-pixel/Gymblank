# GymSlot — Dokumentasi Phase 4 (Booking & Attendance)

**Tanggal:** 4 November 2026  
**Status:** Phase 4 ✅ SELESAI (implementasi + verifikasi)  
**Versi:** 1.0.0  
**Lihat juga:** docs1.md (P0/P1), docs2.md (P2), docs3.md (P3)

---

## Ringkasan

Dokumen ini mencatat semua perubahan dan fitur yang diimplementasikan untuk Phase 4 — Booking & Attendance, sesuai PRD.md bagian 13–14 dan TECHNICAL_DOCUMENTATION.md bagian 4.8–4.10.

---

## Fitur Baru Phase 4

| Fitur | PRD Ref | Status | Keterangan |
|-------|---------|--------|------------|
| Booking jadwal oleh member/staff | 13 | ✅ | Validasi keanggotaan aktif, status jadwal & fasilitas, duplikat, kapasitas |
| Pencegahan overbooking (konkurensi) | 13 langkah 6–7 | ✅ | ScriptLock + validasi ulang kapasitas DI DALAM lock |
| Pembatalan booking | 13 | ✅ | Member hanya booking miliknya; staff bisa semua; cancelled_at tercatat |
| Riwayat booking member | 13 | ✅ | Action `bookings.my` (filter per member yang login) |
| Pencatatan kehadiran (check-in manual) | 14 | ✅ | Waktu SERVER (bukan perangkat), kebijakan gym dihormati |
| Pengaturan attendance | 14 | ✅ | attendance_device_mode, attendance_booking_policy, manual_attendance_enabled |
| Pengaturan gym (owner only) | 14 | ✅ | Upsert tab Settings, validasi nilai, all-or-nothing |

---

## Perubahan Backend (Google Apps Script)

### File Baru

| File | Fungsi |
|------|--------|
| `src/services/bookingService.gs` | create (alur PRD 13 lengkap + LockService), cancel, countActiveForSchedule, findActiveByMemberAndSchedule. Status aktif yang menghabiskan kapasitas: Pending, Confirmed |
| `src/services/attendanceService.gs` | checkIn manual: cek manual_attendance_enabled, kebijakan booking_required/walk_in_allowed, booking harus Confirmed & milik member, anti check-in ganda, waktu server |
| `src/services/gymSettingsService.gs` | getAll/get/update tab Settings; hanya 4 key dikenal; validasi nilai (isIn); update all-or-nothing (validasi dulu baru tulis); upsert per key |

### File Direvisi

| File | Perubahan |
|------|-----------|
| `src/core/router.gs` | +8 action: bookings.list/my/create/cancel, attendance.list/checkin, settings.get/update. Cancel: member hanya boleh batalkan booking milik sendiri; staff semua |
| `src/core/errors.gs` | +1 kode: BOOKING_NOT_FOUND |

### Action API Baru

| Action | Permission | Deskripsi |
|--------|-----------|-----------|
| `bookings.list` | staff (owner/admin/trainer) | Semua booking gym |
| `bookings.my` | semua role | Booking milik member yang login |
| `bookings.create` | semua role | Buat booking (validasi bertingkat + lock) |
| `bookings.cancel` | pemilik booking / staff | Batalkan booking |
| `attendance.list` | staff | Daftar kehadiran |
| `attendance.checkin` | semua role | Check-in manual (aturan gym dihormati) |
| `settings.get` | semua role | Baca pengaturan gym |
| `settings.update` | owner | Ubah pengaturan (validasi nilai) |

### Alur Booking (PRD 13) — Implementasi Langkah demi Langkah

```
1. Member memilih jadwal                     → payload {gym_id, member_id, schedule_id}
2. Backend cek status keanggotaan            → hanya Active yang boleh (PRD 10)
3. Backend cek status jadwal + fasilitas     → keduanya harus Active
4. Backend cek kapasitas (fast-path)         → activeCount < capacity
5. Backend cek booking duplikat              → satu booking aktif per jadwal per member
6. Backend mengunci proses                   → LockService.getScriptLock().tryLock(10s)
7. Validasi ulang di dalam lock              → duplikat + kapasitas DICEK ULANG
8. Backend menyimpan booking                 → status Confirmed, booking_time = waktu server
9. Hasil dikembalikan ke Flutter             → {booking: {...}}
```

Error yang mungkin: `DUPLICATE_BOOKING`, `CAPACITY_FULL`, `RATE_LIMITED` (lock gagal), `MEMBER_NOT_FOUND`, `SCHEDULE_NOT_FOUND`, `FACILITY_NOT_FOUND`, `PERMISSION_DENIED` (bukan anggota aktif), `VALIDATION_ERROR` (jadwal/fasilitas tidak aktif).

Kegagalan lock TIDAK menggagalkan integritas: jika tryLock gagal, request ditolak dengan `RATE_LIMITED` — klien dapat mencoba lagi.

### Aturan Attendance (PRD 14)

- `check_in_at` selalu dari server (`DateTimeHelper.nowIso`), tidak pernah dari perangkat.
- `manual_attendance_enabled != true` → check-in manual ditolak (`PERMISSION_DENIED`).
- `attendance_booking_policy = booking_required` → `booking_id` wajib; harus Confirmed, milik member tersebut, dan belum pernah di-check-in.
- `walk_in_allowed` → `booking_id` boleh kosong.
- Satu booking hanya bisa di-check-in sekali (`DUPLICATE_BOOKING`).
- `attendance_method` default `manual`; `device_id` opsional.

### Pengaturan Gym (TD 4.10)

| Key | Nilai valid |
|-----|-------------|
| attendance_device_mode | gym_camera, mobile_camera, both |
| attendance_booking_policy | booking_required, walk_in_allowed |
| manual_attendance_enabled | true, false |
| timezone | string zona waktu (mis. Asia/Jakarta) |

Update bersifat all-or-nothing: semua key+value divalidasi SEBELUM ada penulisan; key tidak dikenal menolak seluruh request.

---

## Perubahan Flutter (Frontend)

### File Baru

| File | Fungsi |
|------|--------|
| `lib/models/booking.dart` | Model Booking + getter isActive (Pending/Confirmed) |
| `lib/models/attendance.dart` | Model Attendance |
| `lib/providers/booking_provider.dart` | State management: loadBookings, loadMyBookings, createBooking, cancelBooking, loadAttendance, checkIn, loadSettings, updateSettings. Menyimpan lastError dari backend (mis. pesan CAPACITY_FULL) untuk ditampilkan di UI |

### File Direvisi

| File | Perubahan |
|------|-----------|
| `lib/main.dart` | Daftarkan BookingProvider |
| `lib/features/management/presentation/gym_detail_screen.dart` | +3 tab baru: Booking (list + buat + batalkan dengan konfirmasi), Kehadiran (list + check-in manual), Pengaturan (3 setting dengan dropdown/switch, save via owner). Tab switcher diganti ChoiceChip Wrap (muat 6 tab). +widget _BookingStatusChip (warna per status) |

### UX Error Backend di UI

`lastError` dari BookingProvider ditampilkan sebagai banner merah di tab Booking/Kehadiran/Pengaturan — pengguna melihat pesan asli backend seperti "Kapasitas jadwal sudah penuh" atau "Anda sudah memiliki booking aktif untuk jadwal ini".

---

## Verifikasi Tanpa Error

| Pemeriksaan | Hasil |
|-------------|-------|
| `flutter analyze` | ✅ No issues found! |
| `flutter test` | ✅ 2 passed (All tests passed) |
| `node --check` seluruh file .gs backend | ✅ 31/31 OK |

---

## Alur Pengguna Phase 4

```
Dashboard → pilih gym → GymDetailScreen
  ├── Tab Booking: lihat semua booking (staff), buat booking (pilih anggota+jadwal),
  │   batalkan booking aktif (dialog konfirmasi)
  ├── Tab Kehadiran: lihat riwayat check-in, check-in manual (pilih anggota,
  │   booking opsional jika walk-in diizinkan)
  └── Tab Pengaturan: ubah mode perangkat, kebijakan booking, kehadiran manual (owner)
```

---

## Keputusan Teknis

1. **Status aktif booking = Pending + Confirmed** — keduanya menghabiskan kapasitas. Completed/Cancelled/Rejected tidak.
2. **Fast-path + double-check dalam lock** — cek kapasitas dilakukan dua kali (sebelum dan di dalam lock) sesuai PRD 13 langkah 4 dan 7; langkah 7 adalah keputusan final.
3. **Lock di level Script (global)** — konsisten dengan keputusan MVP (docs1.md); tryLock 10 detik, kegagalan → RATE_LIMITED.
4. **Kebijakan booking/cancel (batas waktu, no-show, waitlist) TIDAK dibuat** — PRD 21 melarang menetapkan kebijakan itu tanpa persetujuan produk. Cancel bebas selama booking belum Cancelled.
5. **Settings hanya 4 key** — sesuai TD 4.10; tidak menambah key baru di luar spesifikasi.
6. **Check-in manual default dinonaktifkan** — gym harus mengaktifkan `manual_attendance_enabled=true` terlebih dahulu (PRD 14: "pencatatan manual jika diaktifkan oleh gym").

---

## Known Limitations

1. **Belum ada UI booking untuk member** — tab Booking saat ini berorientasi staff. Action `bookings.my` sudah tersedia untuk UI member di fase berikutnya.
2. **Kamera/IoT attendance belum ada** — hanya check-in manual; mode perangkat disimpan sebagai setting untuk fase lanjutan (PRD 19: face recognition fase lanjutan).
3. **hasCheckedIn membaca seluruh tab Attendance** — OK untuk MVP; skala besar perlu index per-booking.
4. **Cancel tanpa batas waktu** — bebas membatalkan sampai status Cancelled; kebijakan batas waktu menunggu keputusan produk (PRD 21).
5. **Session masih in-memory** — belum SharedPreferences (warisan docs1.md).

---

## Next Steps (Phase 5 — Dashboard & Statistik)

- Dashboard statistik: total anggota, anggota aktif, booking hari ini, booking mendatang, kehadiran hari ini, booking dibatalkan (PRD 8.1)
- Grafik: tren booking, tren kehadiran, status booking, fasilitas populer, jam ramai
- Filter hari ini / 7 hari / 30 hari / rentang khusus
- Update terakhir + tombol refresh + loading/empty/error state
- Data aktual dari spreadsheet (tanpa data dummy — PRD 8.1)

---

*File ini dibuat sebagai dokumentasi Phase 4 (Booking & Attendance). Untuk referensi lengkap, lihat PRD.md, TECHNICAL_DOCUMENTATION.md, docs1.md, docs2.md, docs3.md.*
