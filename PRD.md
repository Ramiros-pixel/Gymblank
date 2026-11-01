# GymSlot — Product Requirements Document (PRD)

**Versi:** 2.0  
**Status:** Draft — MVP  
**Platform:** Android / iOS  
**Bahasa aplikasi:** Indonesia (awal)  
**Arsitektur:** Flutter + Google Apps Script + Google Sheets

---

## 1. Ringkasan Produk

GymSlot adalah aplikasi mobile untuk membantu pengelola gym mengelola operasional, anggota, fasilitas, jadwal, pemesanan, dan kehadiran dalam satu sistem.

Setiap gym memiliki ruang data tersendiri menggunakan Google Spreadsheet. Google Apps Script bertindak sebagai backend yang mengatur komunikasi antara aplikasi Flutter dan Google Sheets.

GymSlot dirancang sebagai aplikasi multi-tenant. Artinya, banyak gym dapat menggunakan aplikasi yang sama, tetapi data setiap gym harus terisolasi.

## 2. Tujuan Produk

1. Mempermudah gym mengelola anggota dan fasilitas.
2. Mempermudah anggota melakukan booking jadwal.
3. Mempermudah pencatatan kehadiran.
4. Menyediakan dashboard statistik untuk pengelola gym.
5. Menggunakan Google Sheets sebagai penyimpanan operasional.
6. Mengurangi biaya infrastruktur untuk tahap MVP.
7. Menyediakan fondasi untuk pengembangan fitur premium.

## 3. Target Pengguna

### 3.1 Gym Owner
Pemilik gym yang mendaftarkan gym dan menjadi administrator utama.

### 3.2 Gym Admin
Pengelola yang membantu mengatur anggota, fasilitas, jadwal, booking, dan laporan.

### 3.3 Trainer
Pelatih yang dapat melihat jadwal dan anggota sesuai permission.

### 3.4 Member
Anggota gym yang dapat melihat jadwal, melakukan booking, dan melihat riwayat kehadiran.

### 3.5 Platform Super Admin
Pengelola platform GymSlot. Tidak otomatis memiliki akses untuk membaca seluruh data pribadi setiap gym.

## 4. Ruang Lingkup MVP

Fitur yang wajib tersedia:

- Registrasi dan login.
- Login menggunakan Google.
- Logout.
- Pemulihan akses akun melalui mekanisme akun Google.
- Pendaftaran gym.
- Integrasi Google Drive dan Google Sheets.
- Manajemen pengguna dan role.
- Manajemen anggota.
- Manajemen fasilitas.
- Manajemen jadwal.
- Booking jadwal.
- Pembatalan booking.
- Pencatatan kehadiran.
- Dashboard statistik.
- Pengaturan gym.
- Audit log dasar.

Fitur yang dapat dikembangkan setelah MVP:

- Pembayaran premium menggunakan Midtrans.
- Face recognition.
- Verifikasi kehadiran berbasis kamera.
- Analitik lanjutan.
- Waitlist booking.
- Notifikasi otomatis.
- Integrasi perangkat IoT.

## 5. Teknologi

| Komponen | Teknologi |
|---|---|
| Mobile frontend | Flutter |
| Backend/API | Google Apps Script |
| Database operasional | Google Sheets |
| Identitas pengguna | Google Sign-In |
| Integrasi Google | Google OAuth 2.0 |
| Grafik Flutter | Library chart Flutter |
| Pembayaran | Midtrans (fase lanjutan) |
| Face recognition | Python FastAPI (fase lanjutan) |

Tidak menggunakan MySQL, Golang, atau Appwrite Database dalam arsitektur MVP ini.

## 6. Autentikasi dan Akun

### 6.1 Login

Pengguna dapat masuk menggunakan akun Google.

Sistem harus:
- Mengambil Google ID token dari proses Google Sign-In.
- Mengirim token ke backend.
- Memvalidasi token di backend.
- Memastikan audience, issuer, masa berlaku, dan status email sesuai.
- Mengidentifikasi pengguna menggunakan Google subject (`sub`), bukan hanya email.
- Membuat atau memperbarui profil pengguna setelah identitas tervalidasi.

Backend tidak boleh mempercayai identitas atau role yang dikirim secara langsung oleh Flutter.

### 6.2 Logout

Aplikasi menghapus sesi lokal dan token yang digunakan untuk sesi aplikasi.

### 6.3 Pemulihan Akun

Pada MVP, pemulihan akun dilakukan melalui mekanisme pemulihan akun Google karena identitas utama menggunakan Google Sign-In.

GymSlot tidak menyimpan password Google pengguna.

## 7. Pendaftaran Gym

Gym Owner dapat membuat gym melalui aplikasi.

Informasi yang dikumpulkan:
- Nama gym.
- Alamat.
- Nomor telepon.
- Email kontak.
- Deskripsi.
- Logo (opsional).
- Informasi zona waktu.

Alur pendaftaran:

1. Owner login ke GymSlot.
2. Owner memilih menu buat gym.
3. Owner mengisi informasi gym.
4. Backend membuat identitas gym dan status pendaftaran sementara.
5. Owner memberikan izin Google Drive dan Google Sheets.
6. Backend membuat spreadsheet khusus gym.
7. Backend membuat seluruh tab dan header yang diperlukan.
8. Backend menyimpan ID spreadsheet pada metadata gym.
9. Backend memvalidasi struktur spreadsheet.
10. Gym diaktifkan jika seluruh proses berhasil.

Pembuatan spreadsheet harus idempotent. Jika proses gagal dan diulang, sistem harus memeriksa apakah spreadsheet sebelumnya sudah dibuat agar tidak menghasilkan file duplikat.

## 8. Struktur Google Spreadsheet

Setiap gym mempunyai spreadsheet terpisah.

Nama default file: `GymBooking`

Tab yang wajib dibuat:

1. `Dashboard`
2. `Gym`
3. `Users`
4. `Members`
5. `Facilities`
6. `Schedules`
7. `Bookings`
8. `Attendance`
9. `Settings`
10. `AuditLogs`

Setiap data operasional wajib memiliki ID unik. Jangan menggunakan nomor baris sebagai identitas data.

### 8.1 Dashboard Spreadsheet

Dashboard harus mempunyai tampilan profesional dan mudah dipahami.

Warna utama:
- Hijau tua.
- Hijau muda.
- Putih.

Statistik:
- Total anggota.
- Anggota aktif.
- Booking hari ini.
- Booking mendatang.
- Kehadiran hari ini.
- Booking dibatalkan.

Grafik:
- Tren booking.
- Tren kehadiran.
- Status booking.
- Fasilitas populer.
- Jam ramai.

Data dashboard harus berasal dari data aktual. Jika belum ada data, tampilkan nilai nol atau empty state, bukan data contoh yang seolah-olah nyata.

## 9. Manajemen Pengguna dan Permission

Role awal:

| Role | Hak akses utama |
|---|---|
| Gym Owner | Semua pengaturan dan pengelolaan gym |
| Gym Admin | Operasional gym sesuai permission |
| Trainer | Jadwal, anggota, dan kehadiran sesuai permission |
| Member | Melihat jadwal, booking, dan riwayat sendiri |

Permission harus diperiksa backend pada setiap permintaan.

Satu pengguna dapat menjadi anggota lebih dari satu gym. Role pengguna ditentukan berdasarkan keanggotaan pada gym tertentu, bukan role global.

Owner dapat mengundang pengguna melalui email. Pengguna menerima undangan setelah login menggunakan akun yang sesuai.

Mekanisme anggota bergabung melalui kode gym, undangan, atau permintaan bergabung masih memerlukan keputusan produk sebelum implementasi.

## 10. Manajemen Anggota

Data anggota minimal:

- `member_id`
- `user_id`
- `full_name`
- `email`
- `phone`
- `join_date`
- `membership_status`
- `created_at`
- `updated_at`

Status:
- Active
- Inactive
- Suspended

Hanya anggota aktif yang dapat melakukan booking.

## 11. Manajemen Fasilitas

Data fasilitas:
- `facility_id`
- `gym_id`
- `facility_name`
- `description`
- `capacity`
- `status`
- `created_at`
- `updated_at`

Status:
- Active
- Inactive
- Maintenance

Fasilitas yang sedang maintenance tidak dapat dipilih untuk booking baru.

## 12. Manajemen Jadwal

Data jadwal:
- `schedule_id`
- `facility_id`
- `schedule_date`
- `start_time`
- `end_time`
- `capacity`
- `status`
- `created_at`
- `updated_at`

Sistem harus mencegah jadwal yang bertabrakan pada fasilitas yang sama.

## 13. Booking

Status booking:

- Pending
- Confirmed
- Completed
- Cancelled
- Rejected

Alur booking dasar:

1. Member memilih fasilitas dan jadwal.
2. Backend memeriksa status keanggotaan.
3. Backend memeriksa status jadwal.
4. Backend memeriksa kapasitas.
5. Backend memeriksa booking duplikat.
6. Backend mengunci proses perubahan data.
7. Backend memvalidasi ulang kapasitas.
8. Backend menyimpan booking.
9. Backend mengembalikan hasil kepada Flutter.

Sistem harus mencegah overbooking, termasuk ketika beberapa anggota melakukan booking secara bersamaan.

Aturan batas waktu booking, pembatalan, no-show, dan waitlist belum ditetapkan. Jangan membuat kebijakan tersebut tanpa persetujuan produk.

## 14. Attendance

Attendance digunakan untuk mencatat kehadiran anggota gym.

Metode yang direncanakan:
- Kamera di gym.
- Kamera perangkat mobile.
- Kombinasi keduanya.
- Pencatatan manual jika diaktifkan oleh gym.

Pengaturan:
- `attendance_device_mode`: `gym_camera`, `mobile_camera`, atau `both`.
- `attendance_booking_policy`: `booking_required` atau `walk_in_allowed`.
- `manual_attendance_enabled`: boolean.

Data attendance:
- `attendance_id`
- `member_id`
- `booking_id` (opsional jika walk-in diperbolehkan)
- `check_in_at`
- `attendance_method`
- `device_id` (opsional)
- `created_by`

Waktu check-in harus menggunakan waktu server, bukan waktu perangkat pengguna.

## 15. Dashboard Flutter

Dashboard tersedia untuk Owner dan role yang memiliki permission.

Kartu statistik:
- Total anggota aktif.
- Booking hari ini.
- Kehadiran hari ini.
- Booking pending.

Grafik:
- Tren booking.
- Status booking.
- Tren kehadiran.
- Fasilitas populer.
- Jam ramai.

Filter:
- Hari ini.
- 7 hari terakhir.
- 30 hari terakhir.
- Rentang tanggal khusus.

Dashboard menampilkan:
- Waktu pembaruan terakhir.
- Tombol refresh.
- Loading state.
- Empty state.
- Error state.

Semua statistik harus berasal dari gym yang sedang aktif. Tidak boleh ada pencampuran data antar-gym.

## 16. Google Sheets Integration

Setiap gym memiliki spreadsheet sendiri.

Integrasi dilakukan otomatis melalui backend.

Owner memberikan izin Google Drive/Sheets pada saat pembuatan gym atau ketika melakukan koneksi ulang.

Pengguna lain tidak perlu menghubungkan Google Sheets.

Ketentuan:
- Flutter tidak boleh mengakses Google Sheets secara langsung.
- Token OAuth tidak boleh disimpan di Flutter.
- ID spreadsheet disimpan dalam metadata internal.
- Refresh token tidak boleh disimpan di tab spreadsheet.
- Backend harus menangani token kedaluwarsa dan pencabutan izin.
- Sistem menyediakan status koneksi: Connected, Disconnected, atau Error.
- Sistem menyediakan proses reconnect.

Penyimpanan token OAuth harus ditinjau secara khusus karena Apps Script bukan pengganti layanan penyimpanan secret khusus. Jangan menyimpan refresh token dalam spreadsheet atau mengirimkannya ke klien.

## 17. Multi-Tenant dan Keamanan

Setiap gym harus memiliki identitas dan spreadsheet berbeda.

Setiap request harus:
1. Memvalidasi identitas pengguna.
2. Mengidentifikasi gym aktif.
3. Memeriksa membership pengguna pada gym tersebut.
4. Memeriksa permission.
5. Mengambil spreadsheet ID dari metadata backend.
6. Menjalankan operasi hanya pada spreadsheet gym yang sah.

Backend tidak boleh menerima spreadsheet ID dari Flutter sebagai sumber otoritas.

Keamanan:
- HTTPS.
- Validasi input.
- Rate limiting.
- Audit log.
- Validasi token.
- Proteksi akses lintas-tenant.
- Proteksi booking bersamaan.
- Penanganan token OAuth.
- Pembatasan akses editor Apps Script.
- Tidak menaruh secret di aplikasi Flutter.

## 18. Pembayaran Premium

Fitur premium merupakan fase lanjutan.

Model pembayaran:
- Langganan per gym.
- Paket bulanan atau tahunan.
- Pembayaran melalui Midtrans.

Backend harus memverifikasi webhook Midtrans. Jangan mempercayai callback pembayaran dari Flutter sebagai bukti pembayaran berhasil.

Status dan harga paket masih perlu ditentukan.

## 19. Face Recognition

Face recognition merupakan fitur premium dan bukan bagian wajib MVP.

Rencana teknologi:
- Python FastAPI sebagai layanan terpisah.
- Enrollment oleh admin berwenang.
- Persetujuan eksplisit dari anggota.
- Penyimpanan template/embedding terenkripsi jika memungkinkan.
- Penghapusan foto sementara.
- Alternatif check-in non-biometrik.

Data biometrik merupakan data sensitif. Kebijakan persetujuan, retensi, penghapusan, false match, dan keamanan harus diselesaikan sebelum fitur ini dirilis.

## 20. Kriteria Penerimaan MVP

MVP dinyatakan memenuhi kebutuhan dasar jika:

1. Pengguna dapat login menggunakan Google.
2. Backend dapat memvalidasi identitas pengguna.
3. Owner dapat mendaftarkan gym.
4. Spreadsheet dapat dibuat dengan struktur tab yang benar.
5. Setiap gym memiliki spreadsheet terpisah.
6. Owner dapat mengelola anggota.
7. Admin dapat mengelola fasilitas dan jadwal sesuai permission.
8. Member dapat melakukan booking.
9. Sistem mencegah booking melebihi kapasitas dalam pengujian konkurensi.
10. Sistem dapat mencatat attendance.
11. Dashboard menampilkan data aktual.
12. Pengguna dari gym A tidak dapat mengakses data gym B.
13. Sistem menangani koneksi Google yang terputus.
14. Sistem menampilkan error yang jelas ketika Google API atau Apps Script gagal.

## 21. Hal yang Belum Diputuskan

AI coding agent tidak boleh menetapkan hal berikut secara sepihak:

- Mekanisme anggota bergabung ke gym.
- Proses verifikasi gym.
- Kebijakan booking dan pembatalan.
- Batas waktu booking.
- Kebijakan no-show.
- Harga paket premium.
- Masa tenggang pembayaran.
- Aturan renewal.
- GPS/geofence.
- Retensi data biometrik.
- Pengalihan kepemilikan gym.
- Kebijakan backup dan pemulihan spreadsheet.
- Batas jumlah anggota dan booking per gym.

## 22. Prinsip Pengembangan

1. Prioritaskan MVP.
2. Gunakan Google Sheets sebagai penyimpanan operasional.
3. Gunakan Google Apps Script sebagai backend.
4. Jangan menambahkan MySQL, Golang, atau Appwrite tanpa persetujuan.
5. Jangan membuat fitur di luar PRD tanpa mendokumentasikan perubahan.
6. Jangan membuat data dummy seolah-olah data nyata.
7. Semua operasi penting harus memiliki validasi dan penanganan error.
8. Setiap perubahan harus mempertahankan isolasi data antar-gym.
9. Dokumentasikan keputusan teknis dan keterbatasan platform.
10. Jika ada kebutuhan yang tidak dapat dipenuhi secara aman oleh Apps Script dan Sheets, laporkan keterbatasannya sebelum mengganti arsitektur.