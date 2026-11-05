# GymSlot — Dokumentasi Phase 5 (Dashboard & Statistik)

**Tanggal:** 4 November 2026  
**Status:** Phase 5 ✅ SELESAI (implementasi + verifikasi)  
**Versi:** 1.0.0  
**Lihat juga:** docs1.md (P0/P1), docs2.md (P2), docs3.md (P3), docs4.md (P4)

---

## Ringkasan

Dokumen ini mencatat semua perubahan dan fitur yang diimplementasikan untuk Phase 5 — Dashboard & Statistik, sesuai PRD.md bagian 8.1 dan 15: kartu statistik, lima grafik, filter rentang waktu, serta state loading/empty/error dengan data aktual tanpa data dummy.

---

## Fitur Baru Phase 5

| Fitur | PRD Ref | Status | Keterangan |
|-------|---------|--------|------------|
| Kartu statistik (6 kartu) | 15 | ✅ | Total anggota, anggota aktif, booking hari ini, booking mendatang, kehadiran hari ini, booking dibatalkan |
| Grafik tren booking | 8.1 | ✅ | Bar chart per hari (booking dibuat pada rentang) |
| Grafik tren kehadiran | 8.1 | ✅ | Bar chart per hari (check_in_at dikonversi ke tanggal lokal gym) |
| Grafik status booking | 8.1 / 15 | ✅ | Chips berjumlah per status (Pending/Confirmed/Completed/Cancelled/Rejected) |
| Grafik fasilitas populer | 8.1 | ✅ | Bar horizontal berperingkat (booking aktif per fasilitas) |
| Grafik jam ramai | 8.1 | ✅ | Bar chart per jam mulai jadwal |
| Filter hari ini / 7 hari / 30 hari / rentang khusus | 15 | ✅ | ChoiceChip + showDateRangePicker untuk kustom |
| Waktu pembaruan terakhir | 15 | ✅ | generated_at ditampilkan di atas kartu |
| Tombol refresh | 15 | ✅ | Di appbar + pull-to-refresh |
| Loading / empty / error state | 15 | ✅ | Spinner saat awal, pesan "Belum ada data" per grafik, layar error + Coba Lagi |
| Isolasi data antar-gym | 15 | ✅ | Semua angka hanya dari spreadsheet gym yang di-resolve TenantResolver |

---

## Perubahan Backend (Google Apps Script)

### File Baru

| File | Fungsi |
|------|--------|
| `src/services/dashboardService.gs` | Agregasi dari tab Members, Schedules, Bookings, Attendance: `getStats` (kartu) dan `getCharts` (5 grafik + rentang). Zona waktu "hari ini" mengikuti `timezone` di tab Settings gym (fallback Asia/Jakarta) via `Utilities.formatDate` |

### File Direvisi

| File | Perubahan |
|------|-----------|
| `src/core/router.gs` | +2 action: `dashboard.stats`, `dashboard.charts` (permission: semua role dengan membership aktif; spreadsheet ID tetap dari TenantResolver) |

### Action API Baru

| Action | Payload | Respons |
|--------|---------|---------|
| `dashboard.stats` | `{gym_id}` | `{stats: {total_members, active_members, bookings_today, upcoming_bookings, attendance_today, cancelled_bookings, generated_at}}` |
| `dashboard.charts` | `{gym_id, range, start_date?, end_date?}` — range: `today` \| `7d` \| `30d` \| `custom` | `{charts: {range, start_date, end_date, booking_trend[], attendance_trend[], booking_status{}, popular_facilities[], busy_hours[], generated_at}}` |

### Logika Agregasi

1. **Hari ini** = tanggal zona waktu gym (dari Settings), bukan UTC mentah. Timestamp ISO (booking_time, check_in_at, created_at) dikonversi ke tanggal lokal gym sebelum dibandingkan.
2. **Booking hari ini / mendatang** = status aktif (Pending/Confirmed) dengan `schedule_date` == hari ini / > hari ini.
3. **Tren booking** = jumlah booking yang *dibuat* (created_at) per hari dalam rentang — menunjukkan aktivitas pemesanan.
4. **Tren kehadiran** = jumlah check-in (check_in_at) per hari.
5. **Status booking** = hanya booking dengan tanggal jadwal dalam rentang.
6. **Fasilitas populer** = booking aktif (Pending/Confirmed/Completed) pada rentang, dikelompokkan per nama fasilitas, diurutkan menurun.
7. **Jam ramai** = booking aktif pada rentang, dikelompokkan per jam mulai jadwal (HH), diurutkan menaik.
8. **Tanpa data dummy** — tab kosong menghasilkan 0 dan array kosong (PRD 8.1).
9. **Validasi custom range** — endDate < startDate ditolak (`VALIDATION_ERROR`).

---

## Perubahan Flutter (Frontend)

### File Baru

| File | Fungsi |
|------|--------|
| `lib/providers/dashboard_provider.dart` | Model `DashboardStats`, `TrendPoint`, `DashboardCharts` + provider `load()` paralel (Future.wait) untuk stats+charts, state isLoading/hasError/range |
| `lib/features/dashboard/presentation/dashboard_stats_screen.dart` | Layar statistik lengkap: 6 kartu statistik (GridView), grafik tren booking & kehadiran & jam ramai (CustomPaint bar chart tanpa dependency eksternal), status booking (chips), fasilitas populer (bar horizontal berperingkat), filter rentang di bottom bar, date range picker untuk kustom, pull-to-refresh, empty/error state |

### File Direvisi

| File | Perubahan |
|------|-----------|
| `lib/main.dart` | Daftarkan DashboardProvider |
| `lib/features/home/presentation/home_screen.dart` | +tombol "Lihat Statistik Gym" di dashboard utama (membuka DashboardStatsScreen gym pertama) |

### Keputusan Teknis Flutter

1. **Tanpa dependency chart eksternal** — grafik digambar dengan `CustomPaint` + `FractionallySizedBox`. PRD hanya menyebut "library chart Flutter" tanpa menetapkan nama; untuk MVP dihosting 2GB RAM (build_runner sebelumnya timeout), dependency baru (fl_chart syncfusion) menambah risiko build. Custom paint cukup untuk bar chart dan mudah diganti nanti.
2. **Label X diringkas** — maksimal 8 label tanggal/jam agar tidak tumpang tindih di layar kecil.
3. **`generated_at` ditampilkan sebagai UTC** — backend mengembalikan ISO UTC; konversi tampilan ke zona gym bisa ditambahkan di fase polish UI.

---

## Verifikasi Tanpa Error

| Pemeriksaan | Hasil |
|-------------|-------|
| `flutter analyze` | ✅ No issues found! |
| `flutter test` | ✅ 2 passed (All tests passed) |
| `node --check` seluruh file .gs backend | ✅ 32/32 OK |

---

## Alur Pengguna Phase 5

```
Dashboard utama → tombol "Lihat Statistik Gym" → DashboardStatsScreen
  ├── 6 kartu statistik (auto-load stats + charts paralel)
  ├── 5 grafik dari data aktual
  ├── Filter: Hari ini / 7 hari / 30 hari / Kustom (date range picker)
  ├── Pull-to-refresh / tombol refresh
  └── Waktu pembaruan terakhir di atas
```

---

## Known Limitations

1. **Tombol statistik membuka gym pertama** — belum ada pemilih gym jika user punya beberapa gym; kartu gym di dashboard tetap membuka detail gym (Phase 3).
2. **Grafik masih bar chart sederhana** — tanpa sumbu Y bernilai dan tooltip; cukup untuk MVP, bisa ditingkatkan dengan library chart nanti.
3. **getCharts membaca seluruh tab** — sama seperti service lain, OK untuk MVP skala kecil.
4. **Dashboard spreadsheet (PRD 8.1)** — PRD juga menyebut tampilan dashboard pada tab Dashboard di spreadsheet gym (hijau tua/hijau muda/putih). Yang diimplementasikan kali ini adalah dashboard di aplikasi Flutter (PRD 15). Format tab Dashboard spreadsheet dapat dikerjakan terpisah.
5. **generated_at dalam UTC** — belum dikonversi ke zona gym di UI.

---

## Next Steps (Phase 6 — Member Experience & Polish)

- UI booking untuk member (lihat jadwal tersedia, booking milik sendiri via `bookings.my` yang sudah tersedia)
- Undangan anggota via email (tab Invitations sudah ada di skema)
- Session persistence (SharedPreferences) — warisan docs1.md
- Dashboard pada tab Dashboard spreadsheet gym (PRD 8.1) — format warna hijau tua/hijau muda/putih
- Polish UI: date/time picker untuk form jadwal, konversi zona waktu tampilan

---

*File ini dibuat sebagai dokumentasi Phase 5 (Dashboard & Statistik). Untuk referensi lengkap, lihat PRD.md, TECHNICAL_DOCUMENTATION.md, docs1.md–docs4.md.*
