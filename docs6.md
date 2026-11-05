# GymSlot — Dokumentasi Phase 6 (Dashboard + Redesign UI Sesuai desain.md)

**Tanggal:** 4 November 2026  
**Status:** Phase 6 ✅ SELESAI (statistik, grafik, filter, cache, refresh, state — plus redesign UI)  
**Versi:** 1.0.0  
**Referensi desain:** `desain.md` v1.1 (Design System & UX Guide)  
**Lihat juga:** docs1.md–docs5.md

---

## Ringkasan

Phase 6 menuntaskan checklist Dashboard pada TECHNICAL_DOCUMENTATION.md (baris 1105–1112): statistik, grafik, filter tanggal, **cache**, refresh, dan empty/error state — lalu menyelaraskan seluruh tampilan dengan `desain.md`: tema Merah · Hitam · Putih (tegas, atletis, maskulin), tipografi Barlow Condensed + Inter yang di-bundle sebagai asset, komponen bersama terpusat, navigasi per-role, status chip sesuai 3.4, pemetaan error code → pesan, dan pembersihan seluruh warna non-token dari layar fitur.

---

## Cache Dashboard (item terakhir checklist Phase 6)

| Aspek | Implementasi |
|-------|--------------|
| Penyimpanan | `CacheService.getScriptCache()` Apps Script (key-value, TTL) |
| TTL | 60 detik — cukup melindungi kuota Sheets API dari refresh beruntun, tetap segar |
| Kunci | `dash:<generation>:stats:<ssId>` dan `dash:<generation>:charts:<ssId>:<range>:<start>:<end>` |
| Invalidasi | `DashboardService.invalidate(ssId)` menaikkan *generation* per gym → semua key lama otomatis tak terpakai tanpa perlu hapus satu per satu |
| Pemanggil invalidate | bookings.create, bookings.cancel, attendance.checkin, members.create/update, schedules.create/update, facilities.create/update, settings.update (hanya jika `timezone` berubah) |
| Kejujuran data | `generated_at` tetap mencatat waktu agregasi; angka cache tidak ditampilkan seolah-olah dihitung baru (desain.md 7 "jujur soal data") |
| Manual refresh | Tombol refresh + pull-to-refresh tetap melewati cache hanya jika generation berubah; selama 60 dtk data identik dijamin oleh invalidasi saat data berubah |

---

## Checklist Fase 6 TECHDOC — Status Akhir

| Item (baris 1105–1112) | Status |
|---|---|
| Statistik | ✅ 6 kartu (getStats) |
| Grafik | ✅ 5 grafik (getCharts) |
| Filter tanggal | ✅ today / 7d / 30d / custom |
| Cache | ✅ CacheService + generation-based invalidation |
| Refresh | ✅ tombol + pull-to-refresh |
| Empty dan error state | ✅ EmptyState / ErrorState / SkeletonBox terpusat |

---

## Yang Diubah Menjadi Sesuai desain.md

### 1. Font Di-bundle sebagai Asset (desain.md 4)

| Item | Sebelum | Sesudah |
|------|---------|---------|
| Barlow Condensed | Hanya fontFamily string, TIDAK ada asset | `assets/fonts/barlow_condensed/` SemiBold + Bold (unduh dari google/fonts) |
| Inter | Tidak ada asset | `assets/fonts/inter/Inter-Variable.ttf` (variable font; semua berat) |
| pubspec.yaml | Tidak ada bagian fonts | Bagian `fonts:` + `assets:` lengkap |

### 2. Tema Terpusat (desain.md 3, 5, 14.3)

`app_theme.dart` ditulis ulang: scaffold putih, app bar putih default, tombol primary merah 52dp radius 12, input border gray-200 + fokus hitam 2 + error merah, card putih border gray-200 tanpa elevasi, dialog radius 16, snackbar hitam floating, bottom sheet radius 24 atas + handle, navigation bar ikon+label hitam saat aktif. `radiusChip` 10 → **999 (pill)**, + `radiusBottomSheet` 24.

### 3. Komponen Bersama Baru `lib/shared/widgets/` (desain.md 14.4)

| Komponen | Isi |
|----------|-----|
| `app_button.dart` | `AppButton` 5 varian (primary merah, secondary hitam, outline hitam 1.5, text, danger outline merah) + state loading + anti double-tap |
| `app_card.dart` | `AppCard` (putih border gray-200 radius 16), `HeroCard` (hitam aksen merah), `StatCard` (angka Barlow 34 + ikon kanan atas), `GymBanner` (Pending abu / Suspended hitam / Disconnected merah solid / SetupFailed red-tint, sesuai 3.4) |
| `app_states.dart` | `EmptyState` (ikon + judul + tombol), `ErrorState` (peringatan + Coba lagi), `SkeletonBox` (gray-50), `showSuccessSnack` (hitam + centang), `showErrorSnack` (red-tint + peringatan) |
| `app_inputs.dart` | `AppTextField` (label di atas, tinggi 52, fokus hitam 2, error merah), `AppFilterChip` (pill, terpilih hitam), `messageForError` (pemetaan error.code → pesan bagian 10), `gymAppBar` (hitam kapital Barlow), `plainAppBar` (putih) |
| `status_chip.dart` | `StatusChip` sesuai **3.4**: Pending outline abu + jam, Confirmed isi hitam + centang, Completed isi gray-200 + centang ganda, Cancelled outline merah + silang, Rejected isi red-tint + larangan; + Active/Inactive/Maintenance. Status dibedakan bentuk+ikon+label, bukan warna saja |

### 4. Layar Ditulis Ulang

| Layar | Perubahan desain |
|-------|------------------|
| **Login** (8.2) | Logo kotak merah "G" + GYMSLOT Barlow kapital, tombol merah full-width 52dp dengan state loading (spinner putih), snackbar gagal "Gagal masuk. Coba lagi." |
| **Home/Belum punya gym** (8.3) | Dua kartu pilihan: "Buat gym baru" (Untuk pemilik gym) dan "Punya undangan" (Gabung ke gym yang ada) dengan ikon merah |
| **Navigasi per-role** (7.1–7.3) | Owner/Admin: Dashboard, Jadwal, Anggota, Lainnya (4 tab). Member: Beranda, Jadwal, Booking, Profil (4 tab). Trainer: Jadwal (baca saja), Profil (2 tab). Semua via shell `_RoleNavShell` |
| **Lainnya** (7.2) | Daftar menu: Fasilitas, Jadwal, Booking, Kehadiran, Pengaturan Gym, Koneksi Google, Profil + GymBanner status gym di atas |
| **Dashboard** (9) | App bar **hitam** dengan judul DASHBOARD Barlow, 6 kartu statistik (angka Barlow besar, tanpa warna-warni), grafik bar **hitam dengan nilai tertinggi merah** (aturan 9), fasilitas populer bar hitam + nomor peringkat, status booking pakai StatusChip 3.4, filter range tetap di bawah |
| **Daftar Gym** (8.4) | Judul kapital Barlow, error banner red-tint + ikon, sukses kartu hitam + centang, tombol merah 52dp state loading |
| **GymDetail** (6 tab) | FAB **merah** (8.8), semua chip status → StatusChip terpusat, error banner red-tint + rounded |
| **home_screen.dart** | Dihapus alias warna duplikat (`AppColorsStatic`/`AppSpacingStatic`) — semua lewat token asli |

### 5. Pembersihan Warna (Aturan 1.5: "jangan menulis nilai warna di widget fitur")

- Semua `Colors.blue/green/orange/purple/teal/indigo/red.shade50/grey.*` di layar fitur **dihapus** dan diganti token `AppColors`.
- Verifikasi akhir: **0 warna non-token** di `lib/features/` + `lib/main.dart`. Hex hanya ada di `core/theme/app_colors.dart` (sumber tunggal token) dan komentar.

---

## Hal yang Tidak Diubah (Sengaja)

1. **Menu trainer read-only** — navigasi 2 tab sudah benar; sheet daftar member per slot menunggu jawaban pertanyaan terbuka #1 desain.md (trainer boleh lihat nama member atau tidak).
2. **Slot card + strip tanggal + konfirmasi booking member** — layar Jadwal member/booking flow penuh (8.6) membutuhkan endpoint sisa-slot per jadwal yang belum ada di backend Phase 4; jangan membuat sisa slot dihitung UI (8.6: "UI tidak menghitung sisa slot sendiri").
3. **6 pertanyaan terbuka desain.md 17** — tidak ditebak (Pending menghabiskan kapasitas? batas booking harian? dsb).

---

## Verifikasi Tanpa Error

| Pemeriksaan | Hasil |
|-------------|-------|
| `flutter pub get` (font asset baru) | ✅ exit 0 |
| `flutter analyze` | ✅ No issues found! |
| `flutter test` | ✅ 2 passed |
| `node --check` backend 32 file .gs | ✅ 32/32 OK |
| Grep warna non-token di features/main | ✅ 0 hasil |
| Test login tetap lulus (teks tombol & logo tak berubah) | ✅ |

---

## Struktur Akhir UI

```text
lib/
  core/theme/          app_colors, app_typography, app_spacing, app_theme
  shared/widgets/      app_button, app_card, app_inputs, app_states, status_chip
  features/
    authentication/    login_screen (hitam, tombol merah)
    onboarding/        register_gym_screen + GoogleDriveConnectScreen
    home/              home_screen (per-role nav)
    management/        gym_detail_screen (6 tab)
    dashboard/         dashboard_stats_screen (app bar hitam)
  providers/           auth, gym, integration, management, booking, dashboard
```

---

## Known Limitations

1. **Inter variable font** — dipakai satu file variable TTF; bobot Regular/Medium/SemiBold mengikuti fontWeight property. Jika rendering bobot kurang tajam di beberapa device, ganti ke static TTF per bobot.
2. **Pemilih gym belum ada** — desain.md 7 menyebut pemilih gym di atas Beranda; MVP memakai gym pertama. Menunggu kebutuhan multi-gym nyata.
3. **Cache 60 detik berbasis generation** — tidak ada penghapusan key lama eksplisit; key lama kedaluwarsa sendiri oleh TTL. CacheService Apps Script berbagi kuota script (10MB) — cukup untuk MVP.
4. **Layar member (Beranda/Jadwal member/Booking)** — masih placeholder; menunggu endpoint sisa slot + pertanyaan terbuka #2 dan #3.
5. **Trainer sheet daftar member** — menunggu keputusan pertanyaan #1.

---

## Next Steps (Phase 7 — Penyempurnaan)

- Skeleton loading untuk semua layar data (komponen sudah siap)
- Layar Jadwal member + konfirmasi booking + Booking Saya (butuh endpoint kapasitas per slot + keputusan terbuka #2/#3)
- Undangan via email (tab Invitations)
- Session persistence (SharedPreferences)
- Uji tampilan 360dp dan text scale 130% (desain.md 16)

---

*File ini dibuat sebagai dokumentasi Phase 6 (Redesign UI). Untuk referensi desain lengkap, lihat desain.md; untuk fitur, PRD.md dan TECHNICAL_DOCUMENTATION.md.*
