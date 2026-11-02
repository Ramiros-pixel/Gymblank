# GymSlot — Design System & UX Guide

**Versi:** 1.1
**Status:** Draft — MVP
**Referensi:** `TECHNICAL_DOCUMENTATION.md` v2.0
**Platform:** Flutter (mobile)
**Tema visual:** Merah · Hitam · Putih — tegas, atletis, maskulin, tetap bersih

---

# 1. Cara Memakai Dokumen Ini

Dokumen ini adalah acuan UI/UX untuk developer dan AI coding agent.

Aturan penting:

1. Desain hanya mencakup fitur MVP yang ada di `TECHNICAL_DOCUMENTATION.md` (Phase 1 sampai Phase 7).
2. Midtrans, face recognition, notifikasi, analitik lanjutan, dan IoT adalah **Phase 8**. Jangan dibuatkan layar atau tombol aktif. Jika perlu, cukup siapkan ruang kosong di arsitektur navigasi.
3. Jangan membuat kebijakan bisnis baru lewat UI (misalnya aturan batas pembatalan, jam tutup booking, atau izin trainer). Bagian yang butuh keputusan ditandai **[PERLU KEPUTUSAN]**.
4. Semua keputusan akses (role, gym, spreadsheet) ditentukan backend. UI hanya **menyembunyikan** menu yang tidak relevan, bukan menjadi pengaman.
5. Semua token warna, ukuran, dan komponen di sini harus dipusatkan di `lib/core/theme/` dan `lib/shared/widgets/`. Jangan menulis nilai warna atau ukuran langsung di widget fitur.

---

# 2. Prinsip Desain

| # | Prinsip | Artinya di UI |
|---|---|---|
| 1 | **Satu layar, satu tujuan** | Setiap layar punya satu aksi utama (satu tombol merah). |
| 2 | **Maksimal 3 ketukan** | Booking slot dari Beranda tidak boleh lebih dari 3 ketukan. |
| 3 | **Tegas, bukan ramai** | Hitam dan putih mendominasi. Merah hanya untuk aksi utama dan penekanan. |
| 4 | **Status selalu jelas** | Pengguna selalu tahu: sedang apa, berhasil atau gagal, dan langkah berikutnya. |
| 5 | **Bahasa pendek dan langsung** | Kalimat aktif, tanpa istilah teknis (tidak ada "spreadsheet", "token", "tenant" di teks pengguna biasa). |
| 6 | **Satu tangan** | Aksi utama di area jempol (bawah layar). Navigasi di bawah, bukan di atas. |
| 7 | **Jujur soal data** | Tampilkan `last_updated`. Jangan tampilkan data cache seolah-olah aktual saat integrasi terputus. |

---

# 3. Warna

## 3.1 Palet Inti

| Token | Hex | Penggunaan |
|---|---|---|
| `black` | `#0A0A0A` | App bar gelap, kartu hero, teks utama, bottom nav |
| `charcoal` | `#1A1A1A` | Permukaan gelap sekunder |
| `red` | `#E10600` | Tombol utama, indikator aktif, aksen |
| `red-dark` | `#B30500` | State ditekan (pressed) tombol merah |
| `red-bright` | `#FF4D42` | Merah untuk **teks/ikon di atas latar hitam** (kontras lebih baik) |
| `red-tint` | `#FDECEA` | Latar lembut untuk pesan error/peringatan |
| `white` | `#FFFFFF` | Latar halaman, kartu, teks di atas hitam/merah |
| `gray-50` | `#F5F5F5` | Latar section, skeleton |
| `gray-200` | `#E5E5E5` | Garis pembatas, border input |
| `gray-500` | `#737373` | Teks sekunder, placeholder |
| `gray-700` | `#404040` | Teks sekunder yang lebih tegas |

## 3.2 Aturan Proporsi

```text
Putih / abu muda   ~60%   latar halaman, kartu, daftar
Hitam              ~30%   header, kartu hero, bottom nav, teks
Merah              ~10%   tombol utama, status aktif, angka penting
```

Merah itu mahal. Jika satu layar sudah punya lebih dari satu elemen merah solid, kurangi.

## 3.3 Kontras dan Aksesibilitas

- Teks putih di atas merah `#E10600`: kontras sekitar 5:1 (lulus AA untuk teks normal).
- Merah `#E10600` di atas hitam hanya sekitar 4:1. **Jangan** pakai untuk teks kecil di latar hitam. Gunakan `red-bright` `#FF4D42`.
- Teks utama `#0A0A0A` di atas putih: kontras sangat tinggi.
- Jangan mengandalkan warna saja untuk makna. Selalu pasangkan **ikon + label teks**.

## 3.4 Warna Status (hanya merah, hitam, putih)

Tema dibatasi tiga warna, jadi status dibedakan lewat **bentuk chip, ikon, dan label**, bukan hijau/kuning.

### Status Booking

| Status | Tampilan chip | Ikon |
|---|---|---|
| Pending | Outline abu, teks `gray-700` | jam |
| Confirmed | Isi hitam, teks putih | centang |
| Completed | Isi `gray-200`, teks `gray-700` | centang ganda |
| Cancelled | Outline merah, teks merah | silang |
| Rejected | Isi `red-tint`, teks merah | larangan |

### Status Gym / Integrasi

| Status | Tampilan banner | Pesan singkat |
|---|---|---|
| Pending | Abu, ikon jam | "Gym sedang disiapkan" |
| Active | Tidak ada banner | — |
| Suspended | Hitam, teks putih | "Gym ditangguhkan. Hubungi pengelola platform." |
| Disconnected | Merah solid, teks putih | "Koneksi Google terputus. Hubungkan kembali." |
| SetupFailed | `red-tint`, teks merah | "Penyiapan gagal. Coba lagi." |

### Kapasitas Slot

- Bar progres: isi hitam di atas track `gray-200`.
- Berubah **merah** saat terisi 90% atau lebih.
- Penuh: teks "Penuh" + tombol dinonaktifkan (abu), bukan disembunyikan.
- Jika ada booking dibatalkan, bar kapasitas turun dan tombol aktif lagi setelah layar diperbarui.

---

# 4. Tipografi

| Peran | Font | Catatan |
|---|---|---|
| Judul & angka besar | **Barlow Condensed** (SemiBold/Bold) | Kesan atletis, kuat, hemat ruang. Huruf kapital hanya untuk judul layar dan label hero. |
| Isi, form, tombol, label | **Inter** (Regular/Medium/SemiBold) | Mudah dibaca, netral. |

Font harus di-bundle sebagai asset (jangan hanya mengandalkan unduhan saat runtime) agar tampilan konsisten dan cepat.

## Skala Teks

| Token | Font | Ukuran / Tinggi baris | Berat | Penggunaan |
|---|---|---|---|---|
| `display` | Barlow Condensed | 40 / 44 | Bold | Angka statistik besar |
| `title-lg` | Barlow Condensed | 28 / 32 | Bold | Judul layar (huruf kapital) |
| `title-md` | Barlow Condensed | 22 / 26 | SemiBold | Judul section |
| `body-lg` | Inter | 16 / 24 | Regular | Isi utama |
| `body-md` | Inter | 14 / 20 | Regular | Isi sekunder, deskripsi |
| `label-lg` | Inter | 14 / 20 | SemiBold | Tombol, tab |
| `label-sm` | Inter | 12 / 16 | Medium | Chip, caption, `last_updated` |

Aturan: ukuran teks isi minimal 14. Hormati pengaturan ukuran font sistem (text scale) sampai 130% tanpa teks terpotong.

---

# 5. Layout, Jarak, dan Bentuk

- **Grid jarak 4pt:** 4, 8, 12, 16, 24, 32, 48.
- **Padding halaman:** 16 horizontal.
- **Radius:** kartu 16, tombol 12, input 12, chip 999 (pill), bottom sheet 24 (atas saja).
- **Elevasi:** hindari bayangan tebal. Pakai border `gray-200` 1px untuk kartu putih. Kartu hero hitam tanpa border.
- **Area sentuh minimum:** 48 × 48 dp.
- **Ikon:** satu keluarga ikon outline (misalnya Material Symbols Rounded atau Lucide), ketebalan garis konsisten 2.
- **Mode:** MVP memakai tema terang sebagai default (bersih). Struktur token harus siap untuk mode gelap di kemudian hari. Mode gelap tidak termasuk MVP.

---

# 6. Komponen

## 6.1 Tombol

| Varian | Tampilan | Kapan dipakai |
|---|---|---|
| **Primary** | Isi merah `#E10600`, teks putih, tinggi 52 | Satu aksi utama per layar (Booking, Check-in, Simpan) |
| **Secondary** | Isi hitam, teks putih | Aksi penting kedua (Hubungkan Google) |
| **Outline** | Border hitam 1.5, teks hitam | Aksi netral (Batal, Lihat detail) |
| **Text** | Tanpa isi, teks hitam bergaris bawah halus | Aksi tersier |
| **Danger** | Outline merah, teks merah | Batalkan booking, Putus koneksi |

State: default, pressed (`red-dark`), disabled (`gray-200` + teks `gray-500`), loading (spinner kecil putih, tombol tidak bisa ditekan ulang).

Tombol utama lebar penuh, menempel di area bawah layar pada form dan konfirmasi.

## 6.2 Kartu

- **Kartu standar:** putih, border `gray-200`, radius 16, padding 16.
- **Kartu hero:** hitam, teks putih, satu aksen merah (angka atau garis tipis di sisi kiri 4px).
- **Kartu statistik:** angka `display`, label `label-sm`, ikon kecil di kanan atas.
- **Kartu slot jadwal:** jam besar di kiri, nama fasilitas, bar kapasitas, tombol di kanan/bawah.

## 6.3 Input Form

- Label di atas field (bukan hanya placeholder).
- Tinggi 52, border `gray-200`, fokus border hitam 2.
- Error: border merah + pesan merah di bawah field + ikon.
- Validasi dasar di Flutter (kosong, format email, format telepon). Validasi final tetap di backend.
- Tombol simpan nonaktif sampai field wajib terisi, atau tetap aktif dengan pesan error yang jelas (pilih salah satu dan konsisten).

## 6.4 Chip dan Filter

- Filter tanggal dan fasilitas memakai chip pill.
- Terpilih: isi hitam, teks putih. Tidak terpilih: outline abu.

## 6.5 Navigasi

- **Bottom navigation** maksimal 4 tab, ikon + label selalu terlihat.
- Tab aktif: ikon dan label hitam, indikator garis merah 3px di atas.
- App bar putih (halaman biasa) atau hitam (halaman hero/dashboard).
- Tombol kembali selalu tersedia di layar detail.

## 6.6 Bottom Sheet

Dipakai untuk detail slot, konfirmasi booking, pemilih gym, dan filter. Punya handle di atas, bisa ditutup dengan geser ke bawah, dan tombol aksi utama di bagian bawah.

## 6.7 Umpan Balik

| Jenis | Komponen |
|---|---|
| Berhasil singkat | Snackbar hitam, ikon centang, hilang 3 detik |
| Berhasil penting (booking) | Layar/sheet sukses dengan ringkasan |
| Error ringan | Snackbar `red-tint` dengan ikon peringatan |
| Error yang butuh tindakan | Banner atau kartu error dengan tombol (Coba lagi / Hubungkan kembali) |
| Konfirmasi destruktif | Dialog dengan tombol Danger + Batal |

---

# 7. Peran Pengguna dan Navigasi

Role berasal dari tabel `Memberships`: `owner`, `admin`, `trainer`, `member`. Seorang pengguna bisa punya lebih dari satu gym, sehingga ada **pemilih gym** di bagian atas Beranda.

## 7.1 Member (4 tab)

| Tab | Isi |
|---|---|
| **Beranda** | Slot terdekat, booking berikutnya, tombol booking cepat |
| **Jadwal** | Jelajahi jadwal per tanggal dan fasilitas, lakukan booking |
| **Booking** | Booking mendatang dan riwayat, pembatalan |
| **Profil** | Data diri, kehadiran, ganti gym, keluar |

## 7.2 Owner dan Admin (4 tab)

| Tab | Isi |
|---|---|
| **Dashboard** | Statistik dan grafik |
| **Jadwal** | Kelola jadwal dan lihat booking per slot |
| **Anggota** | Daftar, tambah, ubah, undang anggota |
| **Lainnya** | Fasilitas, Kehadiran, Booking, Pengaturan Gym, Koneksi Google, Profil |

Perbedaan owner dan admin (misalnya hanya owner yang boleh mengelola koneksi Google) mengikuti aturan permission backend. Jika backend menolak, tampilkan pesan `PERMISSION_DENIED`.

## 7.3 Trainer (2 tab, hanya baca)

**Keputusan:** trainer hanya bisa **melihat jadwal member**. Tidak ada aksi mengubah data apa pun.

| Tab | Isi |
|---|---|
| **Jadwal** | Jadwal per tanggal dan fasilitas, bersifat read-only |
| **Profil** | Data diri, ganti gym, keluar |

Isi layar Jadwal trainer:
- Strip tanggal dan chip fasilitas, sama seperti layar Jadwal member.
- Setiap kartu slot menampilkan jam, fasilitas, bar kapasitas, dan jumlah terisi (mis. "5 / 10 terisi").
- Ketuk kartu untuk membuka sheet berisi **daftar member yang memegang slot itu** (booking aktif).
- **Tidak ada** tombol Booking, Batalkan, Ubah, Tambah, ataupun Catat Manual.
- Tidak ada tab Dashboard, Anggota, Kehadiran, atau Lainnya.

```text
+------------------------------+
|  JADWAL                      |
|  [Sen][Sel][Rab][Kam][Jum]   |
|  [Semua] [Cardio] [Beban]    |
|                              |
|  +------------------------+  |
|  | 06:00 - 07:30          |  |
|  | Area Beban             |  |
|  | ####------  5 / 10     |  |
|  | Lihat member >         |  |
|  +------------------------+  |
|                              |
|        [ Jadwal ][ Profil ]  |
+------------------------------+
```

**[ASUMSI — mohon konfirmasi]** "Melihat jadwal member" diterjemahkan sebagai: trainer melihat slot dan nama member yang sudah booking. Jika trainer hanya boleh melihat jadwal tanpa nama member, hapus sheet daftar member dan tampilkan jumlah terisi saja.

## 7.4 Aturan Penyembunyian Menu

- Menu yang tidak boleh diakses role tertentu **tidak ditampilkan**.
- Jika pengguna tetap mencapai aksi yang ditolak backend, tampilkan pesan yang jelas, bukan layar kosong.
- Perubahan `gym_id` di sisi klien tidak pernah memberi akses. UI tidak boleh berasumsi bahwa data gym lain boleh tampil.

---

# 8. Alur Utama (User Flow)

## 8.1 Peta Alur Keseluruhan

```text
Splash
  |
  v
Login (Google Sign-In)
  |
  +--> Punya gym aktif? --Ya--> Beranda sesuai role
  |
  +--> Belum punya gym
          |
          +--> Terima undangan  --> Beranda (member/admin/trainer)
          |
          +--> Buat gym baru    --> Setup Gym --> Hubungkan Google --> Dashboard
```

## 8.2 Login

Tujuan: masuk dalam satu ketukan.

```text
+------------------------------+
|                              |
|          [LOGO]              |
|          GYMSLOT             |
|                              |
|   Booking slot gym.          |
|   Tanpa antre. Tanpa ribet.  |
|                              |
|                              |
|  [ G  Masuk dengan Google ]  |  <- merah solid
|                              |
|  Dengan masuk, kamu setuju   |
|  dengan Syarat & Privasi.    |
+------------------------------+
```

- Latar hitam penuh, logo putih dengan aksen merah, satu tombol.
- Loading: tombol berubah ke state loading. Jangan menampilkan layar kosong.
- Gagal: snackbar "Gagal masuk. Coba lagi." Sesi kedaluwarsa (`AUTH_EXPIRED`): kembali ke login dengan pesan "Sesi berakhir, silakan masuk lagi."

## 8.3 Setelah Login: Belum Punya Gym

Dua kartu besar, sederhana:

```text
Halo, [Nama].
Mau mulai dari mana?

+------------------------------+
|  [ikon]  Buat gym baru       |
|  Untuk pemilik gym           |
+------------------------------+
+------------------------------+
|  [ikon]  Punya undangan      |
|  Gabung ke gym yang ada      |
+------------------------------+
```

## 8.4 Setup Gym (Owner) — Phase 2

Dibagi menjadi langkah pendek dengan stepper di atas. Ada dua izin berbeda yang harus dijelaskan: **masuk dengan Google** (identitas) dan **izin Google Drive/Sheets** (penyimpanan data gym). Jangan digabung menjadi satu penjelasan.

**Langkah 1 — Data Gym**

Field: Nama gym, Alamat, Telepon, Email kontak, Zona waktu (default sesuai perangkat, mis. Asia/Jakarta).
Tombol utama: **Lanjut**.

**Langkah 2 — Hubungkan Google**

```text
+------------------------------+
|  Hubungkan Google Drive      |
|                              |
|  GymSlot akan membuat satu   |
|  file data gym di Drive      |
|  milikmu. Kamu tetap jadi    |
|  pemilik datanya.            |
|                              |
|  [ Hubungkan Google Drive ]  |  <- hitam (secondary)
+------------------------------+
```

Teks harus jujur dan singkat. Hindari menjanjikan hal yang belum terbukti di Phase 0 (kepemilikan spreadsheet dan pengelolaan token).

**Langkah 3 — Penyiapan Otomatis**

Daftar progres dengan centang, bergerak otomatis:

```text
 [v] Gym dibuat
 [v] Izin Google diterima
 [~] Menyiapkan data gym...
 [ ] Memeriksa koneksi
 [ ] Gym aktif
```

- Pembuatan bersifat idempotent. Jika gagal di tengah, tampilkan status **SetupFailed** dengan tombol **Coba lagi**. Retry melanjutkan proses yang sama, bukan membuat ulang dari awal.
- Jangan menyebut ID spreadsheet ke pengguna.

**Langkah 4 — Selesai**

Layar sukses: "Gym siap dipakai." Tombol utama: **Buka Dashboard**.

## 8.5 Terima Undangan

- Pengguna membuka tautan atau memasukkan kode undangan.
- Tampilkan: nama gym, role yang ditawarkan, tombol **Gabung**.
- Undangan kedaluwarsa atau tidak valid: pesan jelas + tombol **Hubungi pengelola gym**.

## 8.6 Alur Booking Member — Phase 4

Alur harus pendek dan aman dari pengiriman ganda.

```text
Beranda / Jadwal
   |
   v
Pilih tanggal  -->  (opsional) filter fasilitas
   |
   v
Ketuk kartu slot
   |
   v
Sheet konfirmasi: fasilitas, tanggal, jam, sisa slot
   |
   v
[ Booking Sekarang ]
   |
   +--> Sukses          --> Layar sukses + "Lihat Booking"
   +--> CAPACITY_FULL   --> "Slot sudah penuh" + saran slot lain
   +--> DUPLICATE_BOOKING --> "Kamu sudah booking slot ini"
   +--> Jaringan putus  --> "Memeriksa status booking..." (kirim ulang dengan request_id yang sama)
```

**Layar Jadwal (member)**

```text
+------------------------------+
|  JADWAL                      |
|                              |
|  [Sen][Sel][Rab][Kam][Jum]   |  <- strip tanggal (terpilih = hitam)
|  [Semua] [Cardio] [Beban]    |  <- chip fasilitas
|                              |
|  +------------------------+  |
|  | 06:00 - 07:30          |  |
|  | Area Beban             |  |
|  | ####------  Sisa 8     |  |
|  |            [ Booking ] |  |
|  +------------------------+  |
|  +------------------------+  |
|  | 07:30 - 09:00          |  |
|  | Area Cardio            |  |
|  | #########-  Sisa 1     |  |  <- bar merah
|  |            [ Booking ] |  |
|  +------------------------+  |
|  +------------------------+  |
|  | 09:00 - 10:30  PENUH   |  |
|  |            [ Penuh ]   |  |  <- abu, nonaktif
|  +------------------------+  |
|                              |
| [Beranda][Jadwal][Booking][Profil]
+------------------------------+
```

Aturan perilaku:

- Saat tombol ditekan: tombol menjadi loading dan tidak bisa ditekan ulang. Backend memakai lock sehingga respons bisa sedikit lebih lama. Tampilkan teks "Memproses booking..." bila lebih dari 1 detik.
- Selalu kirim `request_id` unik per upaya booking dan pakai ulang saat retry.
- Slot terisi kapasitas tidak disembunyikan, tetapi ditandai **Penuh**.
- Jadwal tidak aktif tidak ditampilkan kepada member.
- Member tidak aktif: tampilkan kartu penjelasan "Keanggotaan tidak aktif" + tombol hubungi gym, tombol booking dinonaktifkan.
- **Keputusan:** tidak ada batas waktu pembatalan. Member boleh membatalkan kapan saja selama booking belum selesai (lihat 8.6a).
- **Keputusan:** booking berstatus `Cancelled` tidak menghabiskan kapasitas. Slot langsung tersedia lagi.
- **[PERLU KEPUTUSAN]** Apakah `Pending` dan `Rejected` menghabiskan kapasitas, serta batas jumlah booking per hari. UI jangan menampilkan aturan ini sampai diputuskan.

**Layar Booking Saya**

- Dua tab: **Mendatang** dan **Riwayat**.
- Kartu menampilkan chip status (lihat 3.4), tanggal, jam, fasilitas.
- Aksi **Batalkan** (Danger) muncul selama status booking masih `Pending` atau `Confirmed`, tanpa batas waktu, dengan dialog konfirmasi. Status `Completed`, `Cancelled`, dan `Rejected` tidak punya tombol Batalkan.

## 8.6a Pembatalan dan Pelepasan Slot

Aturan: tidak ada batas waktu. Saat member membatalkan, booking menjadi `Cancelled` (`cancelled_at` terisi) dan slot jam serta hari itu **langsung kosong lagi** untuk semua orang.

```text
Member ketuk [ Batalkan ]
   |
   v
Dialog: "Batalkan booking ini?"
   Area Beban · Rab 12 Nov · 06:00 - 07:30
   [ Ya, Batalkan ]   [ Tidak ]
   |
   v
Backend: status -> Cancelled, isi cancelled_at, kapasitas dihitung ulang
   |
   +--> Sukses --> Snackbar "Booking dibatalkan. Slot kembali tersedia."
   +--> Gagal  --> Pesan error + Coba lagi
```

Dampak di setiap sisi:

| Pihak | Yang terlihat |
|---|---|
| **Member (pembatal)** | Kartu pindah ke tab Riwayat dengan chip **Cancelled** |
| **Member lain** | Slot yang tadinya "Penuh" atau hampir penuh kembali menampilkan sisa slot dan tombol Booking aktif |
| **Trainer** | Jumlah terisi berkurang dan nama member pembatal hilang dari daftar slot itu |
| **Admin / Owner** | Booking tetap tercatat dengan chip Cancelled dan waktu pembatalan (`cancelled_at`); statistik "Booking dibatalkan" di Dashboard bertambah |

Catatan perilaku data:
- Sumber kebenaran ada di backend. UI tidak menghitung sisa slot sendiri.
- Apps Script tidak mengirim push realtime, jadi tampilan lain diperbarui saat **layar dibuka, ditarik untuk refresh, atau kembali ke foreground**. Jangan menjanjikan pembaruan instan lintas perangkat di teks UI.
- Jika member lain menekan Booking pada slot yang sudah terisi lagi sebelum layarnya diperbarui, backend menolak dengan `CAPACITY_FULL` dan UI menampilkan pesan standar.
- Booking yang sudah dibatalkan tidak bisa "dihidupkan" lagi. Member membuat booking baru, dan itu diperlakukan sebagai booking berbeda.

## 8.7 Alur Kehadiran — Phase 5

Metode yang tampil mengikuti pengaturan gym (`attendance_device_mode`, `attendance_booking_policy`, `manual_attendance_enabled`). Jangan menampilkan metode yang dimatikan.

**Member**
- Tombol **Check-in** besar di Beranda saat ada booking yang bisa di-check-in.
- Jika kebijakan `booking_required` dan member tidak punya booking: tampilkan pesan "Kamu belum punya booking untuk sesi ini" + tombol **Lihat Jadwal**.

**Admin**
- Layar **Kehadiran**: daftar hari ini (nama, jam masuk, metode), pencarian, dan tombol **Catat Manual** (hanya muncul jika `manual_attendance_enabled`).
- Riwayat dengan filter tanggal.

Face recognition **tidak** ada di MVP (Phase 8).

## 8.8 Kelola Anggota — Phase 3

- Daftar: avatar inisial, nama, email, chip status keanggotaan, pencarian di atas.
- Tombol tambah mengambang (FAB merah) untuk **Tambah Anggota** dan **Undang via Email**.
- Detail anggota: data, status, riwayat booking dan kehadiran, aksi ubah.
- Hapus/nonaktifkan: gunakan kata **Nonaktifkan** dan dialog konfirmasi. Ikuti kebijakan backend (menonaktifkan atau menghapus).

## 8.9 Kelola Fasilitas dan Jadwal — Phase 3

**Fasilitas:** daftar kartu (nama, kapasitas, status), tambah/ubah lewat form satu layar, **Nonaktifkan** alih-alih hapus.

**Jadwal:** tampilan kalender mingguan sederhana atau daftar per tanggal. Form: fasilitas, tanggal, jam mulai, jam selesai, kapasitas, status. Validasi jam selesai harus setelah jam mulai.

---

# 9. Dashboard — Phase 6

Hanya untuk Owner dan Admin. Data berasal dari spreadsheet gym yang tervalidasi, bukan data dummy.

```text
+------------------------------+
|  [Gym A  v]        [refresh] |  <- app bar hitam
|  DASHBOARD                   |
|  Diperbarui 09:41            |
|                              |
|  [Hari ini][7 hari][30 hari][Kustom]
|                              |
|  +----------+ +----------+   |
|  |  128     | |   96     |   |
|  | Anggota  | | Aktif    |   |
|  +----------+ +----------+   |
|  +----------+ +----------+   |
|  |  42      | |   31     |   |
|  | Booking  | | Hadir    |   |
|  | hari ini | | hari ini |   |
|  +----------+ +----------+   |
|  +----------+ +----------+   |
|  |  17      | |    3     |   |
|  | Mendatang| | Batal    |   |
|  +----------+ +----------+   |
|                              |
|  TREN BOOKING                |
|  [grafik garis hitam,        |
|   titik aktif merah]         |
|                              |
|  JAM RAMAI                   |
|  [grafik batang, tertinggi   |
|   berwarna merah]            |
|                              |
|  FASILITAS POPULER           |
|  1. Area Beban     ######    |
|  2. Area Cardio    ####      |
|                              |
| [Dashboard][Jadwal][Anggota][Lainnya]
+------------------------------+
```

Statistik (sesuai dokumen): total anggota, anggota aktif, booking hari ini, booking mendatang, attendance hari ini, booking dibatalkan.

Grafik: tren booking, tren kehadiran, status booking, fasilitas populer, jam ramai.

Aturan grafik:
- Warna dasar hitam/abu. **Satu** seri sorotan berwarna merah (nilai tertinggi atau hari terpilih).
- Pie/donut status booking memakai pola isi berbeda (hitam, abu, outline merah) + label langsung, bukan legenda warna saja.
- Setiap grafik punya judul, satuan, dan keadaan kosong.

Perilaku:
- Tarik untuk refresh (pull to refresh) dan tombol refresh.
- Selalu tampilkan `last_updated`.
- Gunakan skeleton saat memuat, bukan spinner layar penuh.
- Saat integrasi **Disconnected**: tampilkan banner merah di atas dan **sembunyikan atau tandai** data cache sebagai tidak aktual. Jangan tampilkan angka lama seolah-olah terbaru.

---

# 10. State Layar (Wajib untuk Setiap Layar Data)

Setiap layar yang memuat data harus punya empat state ini.

| State | Tampilan |
|---|---|
| **Loading** | Skeleton `gray-50` yang mengikuti bentuk konten |
| **Empty** | Ikon sederhana, judul singkat, satu kalimat penjelasan, satu tombol aksi |
| **Error** | Ikon peringatan, pesan manusiawi, tombol **Coba lagi** |
| **Content** | Data normal |

## Contoh Empty State

| Layar | Judul | Aksi |
|---|---|---|
| Jadwal | "Belum ada jadwal di hari ini" | Pilih tanggal lain |
| Booking Saya | "Belum ada booking" | Lihat Jadwal |
| Anggota | "Belum ada anggota" | Tambah Anggota |
| Fasilitas | "Belum ada fasilitas" | Tambah Fasilitas |
| Dashboard | "Belum ada data untuk periode ini" | Ubah rentang tanggal |
| Kehadiran | "Belum ada yang check-in" | — |

## Pemetaan Error Code ke Pesan UI

Error dari backend memakai `error.code`. UI menampilkan pesan ramah, bukan teks teknis atau stack trace.

| Code | Pesan untuk pengguna | Aksi |
|---|---|---|
| `AUTH_INVALID` | "Identitas tidak valid. Silakan masuk lagi." | Ke Login |
| `AUTH_EXPIRED` | "Sesi berakhir. Silakan masuk lagi." | Ke Login |
| `PERMISSION_DENIED` | "Kamu tidak punya izin untuk ini." | Kembali |
| `GYM_NOT_FOUND` | "Gym tidak ditemukan." | Pilih gym |
| `TENANT_ACCESS_DENIED` | "Kamu tidak punya akses ke gym ini." | Pilih gym |
| `VALIDATION_ERROR` | "Periksa kembali data yang diisi." | Sorot field |
| `DUPLICATE_BOOKING` | "Kamu sudah booking slot ini." | Lihat Booking |
| `CAPACITY_FULL` | "Slot ini sudah penuh." | Lihat slot lain |
| `GOOGLE_DISCONNECTED` | "Koneksi Google terputus." | Hubungkan kembali |
| `SHEET_NOT_FOUND` | "Data gym tidak ditemukan. Hubungi pemilik gym." | Coba lagi |
| `RATE_LIMITED` | "Terlalu banyak permintaan. Tunggu sebentar." | Coba lagi nanti |
| `INTERNAL_ERROR` | "Terjadi kesalahan. Coba lagi." | Coba lagi |

Pesan bagi member dan pemilik boleh berbeda. Contoh: `GOOGLE_DISCONNECTED` untuk member cukup "Layanan gym sedang tidak tersedia", sedangkan untuk owner ada tombol **Hubungkan kembali**.

---

# 11. Koneksi Google (Owner)

Layar **Lainnya > Koneksi Google** menampilkan status integrasi.

| Status | Tampilan | Aksi |
|---|---|---|
| Terhubung | Kartu putih, ikon centang, "Terhubung" | Putus koneksi (Danger) |
| Terputus | Kartu merah solid | **Hubungkan kembali** |
| Gagal siap | Kartu `red-tint` | **Coba lagi** |

Setelah reconnect: tampilkan progres singkat "Memeriksa koneksi..." lalu hasil. Putus koneksi selalu lewat dialog konfirmasi yang menjelaskan dampaknya dalam bahasa sederhana.

---

# 12. Microcopy

Gaya: pendek, aktif, tegas, tanpa basa-basi berlebihan.

| Hindari | Pakai |
|---|---|
| "Terjadi kesalahan pada sistem, mohon dicoba beberapa saat lagi" | "Terjadi kesalahan. Coba lagi." |
| "Apakah Anda yakin ingin membatalkan?" | "Batalkan booking ini?" |
| "Submit" | "Booking Sekarang" / "Simpan" |
| "Data tidak ditemukan" | "Belum ada booking" |

Label tombol memakai kata kerja yang spesifik. Nada: percaya diri dan mendukung, bukan memarahi.

---

# 13. Aksesibilitas

- Area sentuh minimum 48 dp.
- Kontras sesuai bagian 3.3.
- Semua ikon fungsional punya label semantik (`Semantics` / `tooltip`).
- Urutan fokus dan pembacaan logis dari atas ke bawah.
- Mendukung text scale hingga 130%.
- Animasi singkat (150-250 ms), sederhana (fade, slide pendek). Hormati pengaturan "kurangi gerakan" sistem.
- Pesan error tidak hanya merah: sertakan ikon dan teks.

---

# 14. Implementasi Flutter

## 14.1 Lokasi File (mengikuti struktur di dokumen teknis)

```text
lib/
  core/
    theme/
      app_colors.dart       // token warna
      app_typography.dart   // TextTheme
      app_spacing.dart      // jarak & radius
      app_theme.dart        // ThemeData
  shared/
    widgets/                // tombol, kartu, chip, input, state layar
    components/             // slot_card, stat_card, status_chip, gym_banner
  features/
    authentication/ onboarding/ gym/ dashboard/ members/
    facilities/ schedules/ bookings/ attendance/ profile/
```

## 14.2 Token Warna (contoh)

```dart
// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  static const black = Color(0xFF0A0A0A);
  static const charcoal = Color(0xFF1A1A1A);
  static const red = Color(0xFFE10600);
  static const redDark = Color(0xFFB30500);
  static const redBright = Color(0xFFFF4D42); // teks/ikon merah di atas hitam
  static const redTint = Color(0xFFFDECEA);
  static const white = Color(0xFFFFFFFF);
  static const gray50 = Color(0xFFF5F5F5);
  static const gray200 = Color(0xFFE5E5E5);
  static const gray500 = Color(0xFF737373);
  static const gray700 = Color(0xFF404040);
}
```

## 14.3 Tema (contoh)

```dart
// lib/core/theme/app_theme.dart
ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.red,
    onPrimary: AppColors.white,
    secondary: AppColors.black,
    onSecondary: AppColors.white,
    error: AppColors.red,
    onError: AppColors.white,
    surface: AppColors.white,
    onSurface: AppColors.black,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.white,
    // textTheme: pakai Barlow Condensed untuk display/title, Inter untuk body/label
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.red,
        foregroundColor: AppColors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gray200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.black, width: 2),
      ),
    ),
  );
}
```

## 14.4 Komponen Bersama yang Harus Dibuat Lebih Dulu

1. `AppButton` (primary, secondary, outline, text, danger, dengan state loading)
2. `AppCard` dan `HeroCard`
3. `StatusChip` (pemetaan status booking dan gym sesuai 3.4)
4. `SlotCard` (jam, fasilitas, bar kapasitas, tombol)
5. `StatCard`
6. `GymBanner` (Disconnected, SetupFailed, Suspended, Pending)
7. `EmptyState`, `ErrorState`, `SkeletonBox`
8. `GymSwitcherSheet`
9. `AppTextField` dengan error terpusat

Fitur dibangun dari komponen ini. Dilarang menduplikasi gaya tombol/kartu di dalam folder fitur.

## 14.5 Aturan State dan Jaringan di UI

- Logic bisnis tidak diletakkan di widget (ikuti `TECHNICAL_DOCUMENTATION.md` bagian 10).
- Error API ditangani terpusat lalu dipetakan ke pesan di bagian 10.
- Tombol aksi yang memicu request (booking, simpan) wajib mencegah double tap.
- Jangan menyimpan token, secret, atau ID spreadsheet di UI.

---

# 15. Urutan Pengerjaan UI (Selaras dengan Fase Implementasi)

| Fase | Layar yang dibuat |
|---|---|
| Phase 1 | Splash, Login, pemilih gym, kerangka navigasi per role |
| Phase 2 | Belum punya gym, Setup Gym (4 langkah), status koneksi |
| Phase 3 | Anggota, Fasilitas, Jadwal, Undangan |
| Phase 4 | Jadwal member, konfirmasi booking, Booking Saya, pembatalan dan pelepasan slot, Jadwal read-only untuk trainer |
| Phase 5 | Check-in member, Kehadiran admin, pengaturan metode kehadiran |
| Phase 6 | Dashboard, filter tanggal, grafik, state kosong/error |
| Phase 7 | Penyempurnaan state error, aksesibilitas, uji tampilan di berbagai ukuran layar |

---

# 16. Checklist Kualitas UI

Sebelum sebuah layar dianggap selesai:

- [ ] Hanya ada satu tombol utama merah pada layar
- [ ] Empat state tersedia: loading, empty, error, content
- [ ] Warna hanya memakai token (merah, hitam, putih, abu)
- [ ] Teks isi minimal 14 dan kontras lolos
- [ ] Area sentuh minimal 48 dp
- [ ] Status tidak hanya dibedakan lewat warna
- [ ] Pesan error memakai pemetaan `error.code`
- [ ] Tombol aksi anti double tap
- [ ] Tidak ada aturan bisnis baru yang ditampilkan tanpa persetujuan
- [ ] Menu sesuai role, dan penolakan backend ditangani dengan pesan jelas
- [ ] Diuji di layar kecil (360 dp) dan besar, serta text scale 130%

---

# 17. Keputusan

## Sudah Diputuskan

| # | Keputusan | Dampak pada UI |
|---|---|---|
| 1 | Trainer hanya melihat jadwal member (read-only) | Navigasi 2 tab, tanpa tombol aksi (bagian 7.3) |
| 2 | Tidak ada batas waktu pembatalan booking | Tombol Batalkan selalu ada selama `Pending` / `Confirmed` |
| 3 | Booking `Cancelled` tidak menghabiskan kapasitas, slot langsung kosong lagi | Bagian 8.6a, sisa slot di semua peran |

## Masih Terbuka

| # | Pertanyaan | Dampak pada UI |
|---|---|---|
| 1 | Apakah trainer boleh melihat nama member per slot (asumsi di 7.3) | Sheet daftar member di Jadwal trainer |
| 2 | Apakah `Pending` dan `Rejected` menghabiskan kapasitas | Angka sisa slot dan label Penuh |
| 3 | Batas jumlah booking per member per hari | Pesan dan validasi booking |
| 4 | Kebijakan hapus vs nonaktifkan anggota | Label dan dialog |
| 5 | Hasil Phase 0 (kepemilikan spreadsheet dan token) | Teks penjelasan di langkah Hubungkan Google |
| 6 | Mode gelap perlu dirilis di MVP atau tidak | Cakupan tema |

Jangan menebak jawaban untuk poin di atas. Laporkan sebagai pertanyaan sebelum diimplementasikan.
