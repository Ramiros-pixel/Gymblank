# GymSlot — Technical Documentation & AI Agent Guide

**Versi:** 2.0  
**Status:** Draft — MVP  
**Target:** AI Coding Agent / Developer  
**Frontend:** Flutter  
**Backend:** Google Apps Script  
**Storage:** Google Sheets

---

# 1. Instruksi Utama untuk AI Agent

Dokumen ini menjadi pedoman teknis utama ketika mengembangkan GymSlot.

AI agent wajib mengikuti ketentuan berikut:

1. Jangan menggunakan MySQL.
2. Jangan menggunakan Golang.
3. Jangan menggunakan Appwrite Database.
4. Gunakan Flutter untuk frontend mobile.
5. Gunakan Google Apps Script sebagai backend.
6. Gunakan Google Sheets sebagai penyimpanan data.
7. Terapkan arsitektur multi-tenant.
8. Jangan mengakses Google Sheets secara langsung dari Flutter.
9. Jangan menaruh OAuth refresh token, API secret, atau kredensial privat di Flutter.
10. Jangan mengimplementasikan fitur yang belum disetujui dalam PRD.
11. Jangan membuat asumsi terhadap business rule yang belum diputuskan.
12. Jangan menghapus atau mengganti struktur data tanpa dokumentasi migrasi.
13. Jangan mengklaim fitur selesai sebelum diuji.
14. Jika menemukan keterbatasan teknis Google Apps Script, jelaskan masalah dan alternatifnya sebelum mengubah arsitektur.

**Urutan prioritas referensi:**

1. PRD.md
2. TECHNICAL_DOCUMENTATION.md
3. Keputusan terbaru yang disetujui pemilik proyek.

Jika terdapat konflik, jangan memilih secara diam-diam. Laporkan konflik dan minta keputusan.

# 2. Arsitektur Sistem

## 2.1 Diagram

```text
                    GYMSLOT MOBILE APP
                         Flutter
                            |
                            | HTTPS / JSON
                            v
                  GOOGLE APPS SCRIPT
                      Backend API
                            |
             +--------------+--------------+
             |              |              |
             v              v              v
        Authentication  Authorization   Business Logic
             |              |              |
             +--------------+--------------+
                            |
                            v
                    GOOGLE SHEETS API
                            |
             +--------------+--------------+
             |              |              |
             v              v              v
       Control Sheet    Gym A Sheet     Gym B Sheet
       Platform Data    Operational    Operational
                        Data            Data
```

## 2.2 Tanggung Jawab Komponen

### Flutter

Bertanggung jawab atas:
- UI/UX.
- Navigasi.
- Google Sign-In.
- Pengelolaan sesi lokal.
- Form input.
- Validasi dasar.
- Menampilkan dashboard.
- Mengirim request ke backend.
- Menampilkan loading, error, dan empty state.

Flutter tidak bertanggung jawab atas:
- Menentukan akses pengguna secara final.
- Menentukan spreadsheet tujuan.
- Mengubah data Google Sheets secara langsung.
- Menyimpan refresh token OAuth.
- Menentukan status pembayaran secara mandiri.

### Google Apps Script

Bertanggung jawab atas:
- API endpoint.
- Validasi identitas.
- Otorisasi role dan permission.
- Multi-tenant isolation.
- Business logic.
- Integrasi Google Sheets.
- Integrasi Google Drive.
- Pembuatan spreadsheet.
- Agregasi dashboard.
- Booking validation.
- Audit logging.
- Error handling.

### Google Sheets

Digunakan untuk:
- Menyimpan metadata platform.
- Menyimpan data gym.
- Menyimpan anggota.
- Menyimpan fasilitas.
- Menyimpan jadwal.
- Menyimpan booking.
- Menyimpan attendance.
- Menyimpan konfigurasi gym.
- Menyimpan audit log.

# 3. Strategi Penyimpanan Data

Gunakan dua kelompok spreadsheet.

## 3.1 Control Spreadsheet

Nama default: `GymSlot_Control`

Spreadsheet ini dimiliki dan dikelola oleh operator platform GymSlot.

Tab:

| Tab | Fungsi |
|---|---|
| Users | Identitas pengguna |
| Gyms | Metadata seluruh gym |
| Memberships | Hubungan pengguna dengan gym dan role |
| Invitations | Undangan pengguna |
| Integrations | Metadata integrasi Google |
| PlatformSettings | Konfigurasi platform |
| AuditLogs | Audit aktivitas platform |

Control Spreadsheet tidak boleh dibagikan kepada pengguna gym secara umum.

## 3.2 Gym Spreadsheet

Setiap gym mempunyai satu spreadsheet tersendiri.

Nama default: `GymBooking`

Tab:

| Tab | Fungsi |
|---|---|
| Dashboard | Statistik dan grafik |
| Gym | Informasi gym |
| Users | Pengguna yang memiliki akses ke gym |
| Members | Data anggota |
| Facilities | Data fasilitas |
| Schedules | Jadwal fasilitas |
| Bookings | Data pemesanan |
| Attendance | Data kehadiran |
| Settings | Konfigurasi gym |
| AuditLogs | Aktivitas gym |

Contoh:

```text
GymSlot_Control
    |
    |-- Gym A
    |     |
    |     +-- GymBooking
    |
    |-- Gym B
    |     |
    |     +-- GymBooking
    |
    +-- Gym C
          |
          +-- GymBooking
```

Walaupun nama file sama, setiap gym harus memiliki spreadsheet ID berbeda.

## 3.3 Aturan ID

Gunakan UUID untuk setiap entitas.

Contoh:

```text
user_id       = UUID
gym_id        = UUID
member_id     = UUID
facility_id   = UUID
schedule_id   = UUID
booking_id    = UUID
attendance_id = UUID
```

Jangan menggunakan nomor baris sebagai primary key.

Semua tabel harus memiliki `created_at` dan `updated_at` jika relevan.

Gunakan format tanggal ISO 8601 untuk pertukaran data. Simpan waktu secara konsisten dalam UTC atau dengan offset yang eksplisit, lalu tampilkan sesuai zona waktu gym.

# 4. Data Dictionary

## 4.1 Users

Lokasi: `GymSlot_Control / Users`

| Kolom | Tipe | Keterangan |
|---|---|---|
| user_id | UUID | ID internal |
| google_sub | String | Identitas unik Google |
| email | String | Email pengguna |
| full_name | String | Nama |
| photo_url | String | Foto profil opsional |
| account_status | String | Active/Disabled |
| created_at | DateTime | Waktu pembuatan |
| updated_at | DateTime | Waktu perubahan |

Gunakan `google_sub` sebagai identitas eksternal utama. Jangan menjadikan email sebagai identitas unik permanen karena email dapat berubah.

## 4.2 Gyms

Lokasi: `GymSlot_Control / Gyms`

| Kolom | Tipe |
|---|---|
| gym_id | UUID |
| gym_name | String |
| address | String |
| phone | String |
| contact_email | String |
| timezone | String |
| spreadsheet_id | String |
| owner_user_id | UUID |
| gym_status | String |
| created_at | DateTime |
| updated_at | DateTime |

Status gym:
- Pending
- Active
- Suspended
- Disconnected
- SetupFailed

## 4.3 Memberships

Lokasi: `GymSlot_Control / Memberships`

| Kolom | Tipe |
|---|---|
| membership_id | UUID |
| user_id | UUID |
| gym_id | UUID |
| role | String |
| status | String |
| joined_at | DateTime |

Role:
- owner
- admin
- trainer
- member

## 4.4 Invitations

Lokasi: `GymSlot_Control / Invitations`

| Kolom | Tipe |
|---|---|
| invitation_id | UUID |
| gym_id | UUID |
| email | String |
| assigned_role | String |
| invitation_token_hash | String |
| status | String |
| expires_at | DateTime |
| created_by | UUID |
| created_at | DateTime |

Simpan hash token undangan, bukan token mentah.

## 4.5 Members

Lokasi: `GymBooking / Members`

| Kolom | Tipe |
|---|---|
| member_id | UUID |
| user_id | UUID |
| full_name | String |
| email | String |
| phone | String |
| join_date | Date |
| membership_status | String |
| created_at | DateTime |
| updated_at | DateTime |

## 4.6 Facilities

Lokasi: `GymBooking / Facilities`

| Kolom | Tipe |
|---|---|
| facility_id | UUID |
| gym_id | UUID |
| facility_name | String |
| description | String |
| capacity | Integer |
| status | String |
| created_at | DateTime |
| updated_at | DateTime |

## 4.7 Schedules

Lokasi: `GymBooking / Schedules`

| Kolom | Tipe |
|---|---|
| schedule_id | UUID |
| facility_id | UUID |
| schedule_date | Date |
| start_time | Time |
| end_time | Time |
| capacity | Integer |
| status | String |
| created_at | DateTime |
| updated_at | DateTime |

## 4.8 Bookings

Lokasi: `GymBooking / Bookings`

| Kolom | Tipe |
|---|---|
| booking_id | UUID |
| member_id | UUID |
| schedule_id | UUID |
| booking_status | String |
| booking_time | DateTime |
| cancelled_at | DateTime |
| created_at | DateTime |
| updated_at | DateTime |

Status:
- Pending
- Confirmed
- Completed
- Cancelled
- Rejected

## 4.9 Attendance

Lokasi: `GymBooking / Attendance`

| Kolom | Tipe |
|---|---|
| attendance_id | UUID |
| member_id | UUID |
| booking_id | UUID |
| check_in_at | DateTime |
| attendance_method | String |
| device_id | String |
| created_by | UUID |
| created_at | DateTime |

`booking_id` dapat kosong jika gym mengizinkan walk-in.

## 4.10 Settings

Lokasi: `GymBooking / Settings`

| Key | Contoh Value |
|---|---|
| attendance_device_mode | both |
| attendance_booking_policy | booking_required |
| manual_attendance_enabled | false |
| timezone | Asia/Jakarta |

Jangan membuat kebijakan booking baru sebelum disetujui pemilik produk.

# 5. Google Apps Script Backend

## 5.1 Struktur Project

Gunakan struktur modular dan pisahkan tanggung jawab.

```text
gym-slot-backend/
|
|-- appsscript.json
|
|-- src/
|   |
|   |-- entry/
|   |   |-- doGet.gs
|   |   |-- doPost.gs
|   |
|   |-- config/
|   |   |-- constants.gs
|   |   |-- settings.gs
|   |
|   |-- core/
|   |   |-- router.gs
|   |   |-- response.gs
|   |   |-- errors.gs
|   |   |-- validator.gs
|   |
|   |-- auth/
|   |   |-- googleAuth.gs
|   |   |-- session.gs
|   |
|   |-- middleware/
|   |   |-- authentication.gs
|   |   |-- authorization.gs
|   |   |-- tenantResolver.gs
|   |
|   |-- services/
|   |   |-- userService.gs
|   |   |-- gymService.gs
|   |   |-- memberService.gs
|   |   |-- facilityService.gs
|   |   |-- scheduleService.gs
|   |   |-- bookingService.gs
|   |   |-- attendanceService.gs
|   |   |-- dashboardService.gs
|   |   |-- googleDriveService.gs
|   |
|   |-- repositories/
|   |   |-- controlRepository.gs
|   |   |-- gymRepository.gs
|   |
|   |-- utils/
|       |-- uuid.gs
|       |-- dateTime.gs
|       |-- lock.gs
|       |-- logger.gs
|
|-- tests/
|-- README.md
```

Struktur tersebut adalah panduan logis. Jika keterbatasan Google Apps Script mengharuskan penyesuaian pengelolaan file, pertahankan pemisahan modul dan tanggung jawab.

## 5.2 API Entry Point

Google Apps Script Web App menggunakan:

- `doGet(e)`
- `doPost(e)`

Gunakan satu router untuk memetakan path dan method ke handler.

Contoh format konseptual request:

```json
{
  "action": "members.list",
  "version": "v1",
  "request_id": "unique-request-id",
  "auth": {
    "id_token": "GOOGLE_ID_TOKEN"
  },
  "payload": {
    "gym_id": "gym-uuid"
  }
}
```

Jangan meletakkan ID token, refresh token, atau informasi rahasia pada URL query string.

Catatan: Web App Apps Script tidak menyediakan akses umum ke seluruh HTTP request headers melalui objek event `doPost(e)`. Rancang autentikasi dan routing sesuai kemampuan resmi Apps Script. Jangan mengasumsikan header `Authorization` dapat dibaca seperti pada server HTTP biasa.

## 5.3 Format Response

Berhasil:

```json
{
  "success": true,
  "request_id": "unique-request-id",
  "data": {},
  "message": "Request berhasil"
}
```

Gagal:

```json
{
  "success": false,
  "request_id": "unique-request-id",
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Data tidak valid"
  }
}
```

Jangan mengirim stack trace, token, atau informasi internal ke Flutter.

## 5.4 Endpoint yang Direncanakan

Semua endpoint berikut merupakan rancangan logical API. Implementasi Apps Script dapat menggunakan `action` routing melalui satu URL Web App.

### Authentication

| Action | Fungsi |
|---|---|
| auth.google | Validasi Google ID token dan login |
| auth.me | Mendapatkan profil pengguna |
| auth.logout | Mengakhiri sesi aplikasi |

### Gym

| Action | Fungsi |
|---|---|
| gyms.create | Membuat gym |
| gyms.list | Menampilkan gym pengguna |
| gyms.detail | Detail gym |
| gyms.update | Mengubah informasi gym |
| gyms.status | Status gym dan integrasi |

### Google Integration

| Action | Fungsi |
|---|---|
| google.connect.start | Memulai izin Google Drive |
| google.connect.callback | Menangani OAuth callback |
| google.connect.status | Status integrasi |
| google.reconnect | Menghubungkan kembali |
| google.disconnect | Memutus integrasi |

### Members

| Action | Fungsi |
|---|---|
| members.list | Daftar anggota |
| members.create | Menambah anggota |
| members.detail | Detail anggota |
| members.update | Mengubah anggota |
| members.delete | Menonaktifkan atau menghapus sesuai kebijakan |

### Facilities

| Action | Fungsi |
|---|---|
| facilities.list | Daftar fasilitas |
| facilities.create | Membuat fasilitas |
| facilities.update | Mengubah fasilitas |
| facilities.delete | Menonaktifkan fasilitas |

### Schedules

| Action | Fungsi |
|---|---|
| schedules.list | Daftar jadwal |
| schedules.create | Membuat jadwal |
| schedules.update | Mengubah jadwal |
| schedules.delete | Menghapus atau menonaktifkan jadwal |

### Bookings

| Action | Fungsi |
|---|---|
| bookings.list | Daftar booking |
| bookings.create | Membuat booking |
| bookings.detail | Detail booking |
| bookings.cancel | Membatalkan booking |
| bookings.update-status | Mengubah status sesuai aturan |

### Attendance

| Action | Fungsi |
|---|---|
| attendance.list | Riwayat kehadiran |
| attendance.check-in | Mencatat kehadiran |
| attendance.manual | Kehadiran manual |
| attendance.summary | Ringkasan kehadiran |

### Dashboard

| Action | Fungsi |
|---|---|
| dashboard.summary | Statistik utama |
| dashboard.booking-trend | Tren booking |
| dashboard.attendance-trend | Tren kehadiran |
| dashboard.facilities | Fasilitas populer |
| dashboard.peak-hours | Jam ramai |

# 6. Authentication dan Authorization

## 6.1 Google Sign-In

Alur:

```text
Flutter
  |
  | Google Sign-In
  v
Google Identity
  |
  | ID Token
  v
Flutter
  |
  | Kirim ID Token melalui HTTPS
  v
Apps Script
  |
  | Validasi token
  v
Control Spreadsheet
  |
  | Cari google_sub
  v
User Session / Profile
```

Ketentuan validasi:
- Signature token harus valid.
- Issuer harus sesuai.
- Audience harus sesuai dengan OAuth Client ID GymSlot.
- Token belum kedaluwarsa.
- `sub` tersedia.
- Status email diverifikasi jika email digunakan untuk kebutuhan undangan.

Untuk prototipe, agent dapat menguji verifikasi melalui endpoint token info Google. Namun, endpoint tersebut tidak boleh dianggap sebagai pengganti validasi signature JWT yang ideal untuk sistem produksi. Evaluasi metode verifikasi yang sesuai dan keterbatasan Apps Script sebelum rilis.

Jangan menggunakan email dari request Flutter sebagai bukti identitas.

## 6.2 Session

Setelah ID token tervalidasi, backend menerbitkan sesi aplikasi GymSlot.

Sesi harus:
- Memiliki masa berlaku.
- Memiliki identitas pengguna.
- Tidak memberikan akses lintas-gym secara otomatis.
- Dapat dicabut.
- Tidak disimpan sebagai data publik.
- Tidak menggunakan ID token Google sebagai session permanen.

Karena Apps Script tidak menyediakan mekanisme session database transaksional, implementasi sesi harus memiliki strategi penyimpanan dan validasi yang jelas. Jangan menyimpan session secret dalam tab spreadsheet yang dapat diakses pengguna gym.

## 6.3 Authorization

Setiap operasi wajib menjalankan pemeriksaan:

```text
Request
  |
  v
Validate Session
  |
  v
Resolve User
  |
  v
Resolve Gym Membership
  |
  v
Check Role / Permission
  |
  v
Execute Operation
```

`gym_id` dari Flutter hanya merupakan konteks permintaan, bukan bukti bahwa pengguna memiliki akses.

Backend harus mencari membership pengguna pada Control Spreadsheet sebelum mengakses spreadsheet gym.

# 7. Google Drive dan Sheets OAuth

## 7.1 Perbedaan Izin

Login Google tidak otomatis memberikan izin untuk membuat spreadsheet di Google Drive pengguna.

Ada dua proses:

1. Google Sign-In untuk identitas pengguna.
2. Google OAuth untuk izin Drive dan Sheets.

Jangan menggabungkan keduanya menjadi satu asumsi izin.

## 7.2 Alur Integrasi

```text
Owner Login
    |
    v
Create Gym
    |
    v
Start Google OAuth
    |
    v
Owner Grants Drive / Sheets Permission
    |
    v
OAuth Callback
    |
    v
Backend Obtains Authorized Access
    |
    v
Create GymBooking Spreadsheet
    |
    v
Create Tabs and Headers
    |
    v
Save Spreadsheet ID
    |
    v
Validate Spreadsheet
    |
    v
Activate Gym
```

## 7.3 Kepemilikan Spreadsheet

Target produk adalah setiap spreadsheet gym dibuat pada Google Drive milik Owner yang menghubungkan akun Google.

Ini membutuhkan alur OAuth atas nama Owner, bukan sekadar menjalankan `SpreadsheetApp.create()` dari akun pembuat script.

AI agent wajib membuat proof of concept untuk membuktikan:
- Owner dapat memberikan izin Drive/Sheets.
- Backend memperoleh akses yang benar atas nama Owner.
- Spreadsheet benar-benar dibuat di Drive Owner.
- Refresh token dapat dikelola dengan aman.
- Integrasi dapat dicabut dan disambungkan kembali.
- Setiap gym mendapatkan spreadsheet yang benar.

Gunakan OAuth 2.0 authorization-code flow dan evaluasi library OAuth2 resmi untuk Google Apps Script jika sesuai.

**Peringatan keamanan:** PropertiesService bukan pengganti Secret Manager khusus. Jangan menyimpan refresh token di spreadsheet, source code, log, atau Flutter. Batasi editor Apps Script dan evaluasi risiko penyimpanan token. Jika persyaratan penyimpanan token yang aman tidak dapat dipenuhi, laporkan sebagai blocker sebelum melanjutkan integrasi produksi.

Jangan diam-diam membuat spreadsheet pada Drive operator platform jika persyaratan kepemilikan Owner belum disetujui untuk diubah.

## 7.4 Pembuatan Spreadsheet

Pembuatan harus idempotent.

Contoh:
- Gym berstatus `Pending`.
- Backend membuat spreadsheet.
- Backend menyimpan spreadsheet ID.
- Proses pembuatan tab gagal.
- Owner mencoba lagi.
- Backend memeriksa spreadsheet ID yang telah tersimpan.
- Backend melanjutkan setup spreadsheet yang sama.

Jangan membuat spreadsheet baru pada setiap retry.

## 7.5 Reconnect

Jika Owner mencabut akses:
- Ubah status integrasi menjadi `Disconnected`.
- Jangan menampilkan data cache seolah-olah masih aktual.
- Berikan pesan yang jelas.
- Sediakan tombol reconnect.
- Setelah akses pulih, validasi spreadsheet dan struktur tab.

Jika spreadsheet dihapus, tandai kondisi `SetupFailed` atau status error yang sesuai. Jangan otomatis membuat pengganti tanpa kebijakan pemulihan yang disetujui.

# 8. Booking dan Concurrency

Google Sheets tidak memiliki transaksi database relasional seperti MySQL atau PostgreSQL.

Karena itu, booking harus memiliki perlindungan khusus.

## 8.1 Alur Booking Aman

```text
Receive Booking Request
        |
        v
Validate User and Membership
        |
        v
Acquire Script Lock
        |
        v
Read Schedule
        |
        v
Count Active Bookings
        |
        v
Validate Capacity
        |
        v
Check Duplicate Booking
        |
        v
Write Booking
        |
        v
Flush / Confirm Write
        |
        v
Release Lock
        |
        v
Return Result
```

Gunakan `LockService` untuk mengoordinasikan operasi booking.

Untuk MVP, `ScriptLock` dapat digunakan agar proses booking tidak saling menimpa. Konsekuensinya, booking dari seluruh gym pada deployment yang sama dapat saling menunggu. Ini aman secara sederhana tetapi mengurangi throughput.

Jangan menganggap `LockService` sebagai transaksi database penuh.

## 8.2 Idempotency

Setiap permintaan booking perlu memiliki `request_id` atau idempotency key.

Jika pengguna mengirim ulang request akibat koneksi terputus, backend harus memeriksa apakah operasi sebelumnya sudah berhasil agar tidak membuat booking ganda.

## 8.3 Validasi Kapasitas

Kapasitas dihitung berdasarkan booking yang masih menggunakan slot sesuai aturan status yang disetujui.

Jangan menghitung booking `Cancelled` sebagai kapasitas terpakai.

Aturan status yang dianggap mengonsumsi kapasitas harus dikonfirmasi sebelum implementasi.

## 8.4 Keterbatasan Skala

Google Sheets bukan sistem transaksi untuk booking berintensitas tinggi. Lakukan uji beban dan uji konkurensi sebelum rilis.

Jika pengujian menunjukkan risiko overbooking atau waktu respons tidak dapat diterima, laporkan kebutuhan perubahan arsitektur. Jangan mengklaim sistem aman hanya karena sudah menggunakan lock.

# 9. Dashboard dan Analytics

Dashboard tidak boleh menghitung statistik berdasarkan data dummy.

Backend mengambil data dari spreadsheet gym yang sudah divalidasi.

Statistik:
- Total anggota.
- Anggota aktif.
- Booking hari ini.
- Booking mendatang.
- Attendance hari ini.
- Booking dibatalkan.

Grafik:
- Booking trend.
- Attendance trend.
- Booking status.
- Popular facilities.
- Peak hours.

Gunakan rentang tanggal dan zona waktu gym yang benar.

Untuk mengurangi pemanggilan Google Sheets:
- Baca rentang data secara batch.
- Hindari membaca satu sel berulang kali.
- Gunakan cache dengan masa berlaku singkat bila sesuai.
- Tampilkan `last_updated`.
- Jangan menampilkan cache lama sebagai data aktual setelah integrasi terputus.

# 10. Flutter Project Structure

Gunakan struktur feature-based.

```text
gym_slot/
|
|-- lib/
|   |
|   |-- main.dart
|   |
|   |-- core/
|   |   |-- config/
|   |   |-- constants/
|   |   |-- network/
|   |   |-- error/
|   |   |-- theme/
|   |   |-- utils/
|   |
|   |-- data/
|   |   |-- models/
|   |   |-- repositories/
|   |   |-- services/
|   |
|   |-- features/
|   |   |
|   |   |-- authentication/
|   |   |-- onboarding/
|   |   |-- gym/
|   |   |-- dashboard/
|   |   |-- members/
|   |   |-- facilities/
|   |   |-- schedules/
|   |   |-- bookings/
|   |   |-- attendance/
|   |   |-- profile/
|   |
|   |-- shared/
|       |-- widgets/
|       |-- components/
|
|-- test/
|-- integration_test/
```

Ketentuan:
- Pisahkan UI, state management, repository, dan network service.
- Jangan meletakkan business logic pada widget.
- Gunakan model data yang konsisten.
- Tangani error API secara terpusat.
- Jangan menaruh Google OAuth secret pada aplikasi.
- Jangan mengakses Google Sheets SDK langsung dari Flutter.

AI agent boleh memilih state management Flutter yang sesuai, tetapi harus konsisten dan mendokumentasikan pilihan tersebut.

# 11. API Contract dan Error Handling

Gunakan JSON untuk request dan response.

Error code yang disarankan:

| Code | Arti |
|---|---|
| AUTH_INVALID | Identitas atau sesi tidak valid |
| AUTH_EXPIRED | Sesi kedaluwarsa |
| PERMISSION_DENIED | Tidak memiliki izin |
| GYM_NOT_FOUND | Gym tidak ditemukan |
| TENANT_ACCESS_DENIED | Akses lintas-gym ditolak |
| VALIDATION_ERROR | Input tidak valid |
| DUPLICATE_BOOKING | Booking duplikat |
| CAPACITY_FULL | Kapasitas penuh |
| GOOGLE_DISCONNECTED | Izin Google terputus |
| SHEET_NOT_FOUND | Spreadsheet tidak ditemukan |
| RATE_LIMITED | Batas request terlampaui |
| INTERNAL_ERROR | Kesalahan internal |

Semua error harus mempunyai pesan yang dapat dipahami pengguna dan detail internal yang hanya dicatat di log terbatas.

# 12. Keamanan

Checklist wajib:

- [ ] Google ID token divalidasi backend.
- [ ] Session aplikasi memiliki masa berlaku.
- [ ] Permission diperiksa backend.
- [ ] Tenant isolation diuji.
- [ ] Spreadsheet ID tidak dipercaya dari Flutter.
- [ ] Refresh token tidak disimpan di spreadsheet.
- [ ] Tidak ada API secret di Flutter.
- [ ] Tidak ada token di URL.
- [ ] Input divalidasi.
- [ ] Endpoint penting memiliki rate limit.
- [ ] Booking memiliki idempotency.
- [ ] Booking memiliki mekanisme lock.
- [ ] Audit log tersedia.
- [ ] Error tidak membocorkan informasi sensitif.
- [ ] Akses editor Apps Script dibatasi.
- [ ] Backup dan pemulihan spreadsheet didokumentasikan.

# 13. Google Apps Script Limits dan Operational Constraints

Google Apps Script memiliki:
- Kuota harian.
- Batas waktu eksekusi.
- Batas layanan Google API.
- Batas pemanggilan layanan.
- Potensi throttling.
- Batas konkurensi.

AI agent wajib:
1. Memeriksa kuota dan batas resmi yang berlaku.
2. Menghindari pemanggilan Spreadsheet service berulang.
3. Menggunakan operasi batch.
4. Menggunakan cache secara hati-hati.
5. Menambahkan retry dengan exponential backoff untuk error sementara.
6. Tidak melakukan retry tanpa batas.
7. Menguji request bersamaan.
8. Mencatat penggunaan dan error.

Dokumentasi referensi:
- Apps Script quotas: https://developers.google.com/apps-script/guides/services/quotas
- Apps Script Web Apps: https://developers.google.com/apps-script/guides/web
- Apps Script Lock Service: https://developers.google.com/apps-script/reference/lock
- Apps Script Spreadsheet Service: https://developers.google.com/apps-script/reference/spreadsheet
- Google Identity: https://developers.google.com/identity
- Google OAuth 2.0: https://developers.google.com/identity/protocols/oauth2

# 14. Deployment

## 14.1 Google Apps Script

Langkah:
1. Buat project Google Apps Script.
2. Atur manifest dan scopes minimum.
3. Implementasikan router.
4. Konfigurasikan OAuth Client ID.
5. Implementasikan autentikasi.
6. Implementasikan Control Spreadsheet.
7. Implementasikan gym spreadsheet.
8. Jalankan pengujian.
9. Deploy sebagai Web App.
10. Uji akses dari aplikasi Flutter.
11. Dokumentasikan deployment ID dan versi.

Jangan menyimpan secret atau kredensial privat pada source code.

## 14.2 Flutter

Langkah:
1. Konfigurasi Flutter.
2. Tambahkan package sesuai kebutuhan.
3. Konfigurasi Google Sign-In.
4. Konfigurasi API endpoint.
5. Implementasikan autentikasi.
6. Implementasikan fitur berdasarkan urutan prioritas.
7. Jalankan unit test.
8. Jalankan integration test.
9. Build APK untuk pengujian.

## 14.3 Environment

Pisahkan:
- Development
- Staging
- Production

Jangan menggunakan spreadsheet produksi untuk pengujian.

# 15. Tahapan Implementasi

## Phase 0 — Technical Feasibility

Sebelum membangun seluruh fitur, buktikan:

1. Flutter dapat login menggunakan Google.
2. Apps Script dapat menerima request dari Flutter.
3. Backend dapat memvalidasi Google ID token.
4. Backend dapat membaca dan menulis Control Spreadsheet.
5. Owner dapat mengotorisasi Drive/Sheets.
6. Spreadsheet dapat dibuat di Drive Owner sesuai persyaratan.
7. Refresh token dapat dikelola secara aman.
8. Apps Script dapat menangani request bersamaan.

Phase 0 merupakan tahap wajib. Jangan melanjutkan implementasi integrasi penuh jika kepemilikan spreadsheet dan pengelolaan token belum terbukti.

## Phase 1 — Foundation

- Setup Flutter.
- Setup Apps Script.
- Setup Control Spreadsheet.
- Implementasi Google Sign-In.
- Implementasi validasi identitas.
- Implementasi session.
- Implementasi role dan membership.

## Phase 2 — Gym Onboarding

- Form pendaftaran gym.
- Google OAuth Drive.
- Pembuatan spreadsheet.
- Pembuatan tab.
- Pembuatan header.
- Validasi spreadsheet.
- Status koneksi.

## Phase 3 — Core Management

- Members.
- Facilities.
- Schedules.
- Invitations.
- Permission.

## Phase 4 — Booking

- Daftar jadwal.
- Booking.
- Pembatalan.
- Validasi kapasitas.
- Idempotency.
- Locking.
- Pengujian konkurensi.

## Phase 5 — Attendance

- Check-in.
- Manual attendance.
- Riwayat.
- Pengaturan metode attendance.

## Phase 6 — Dashboard

- Statistik.
- Grafik.
- Filter tanggal.
- Cache.
- Refresh.
- Empty dan error state.

## Phase 7 — Hardening

- Security test.
- Tenant isolation test.
- Load test.
- Quota test.
- Backup test.
- Reconnect test.
- Deployment production.

## Phase 8 — Future Features

- Midtrans.
- Face recognition.
- Advanced analytics.
- Notification.
- IoT integration.

# 16. Testing Requirements

## Authentication

- Login valid.
- Token kedaluwarsa.
- Token tidak valid.
- Token dengan audience salah.
- Pengguna baru.
- Pengguna lama.

## Multi-Tenant

- Owner gym A tidak dapat membaca gym B.
- Admin gym A tidak dapat mengubah gym B.
- Member gym A tidak dapat mengakses data gym B.
- Mengubah `gym_id` pada request tidak boleh memberikan akses.

## Spreadsheet

- Pembuatan spreadsheet berhasil.
- Pembuatan tab berhasil.
- Header sesuai.
- Retry tidak membuat duplikat.
- Spreadsheet tidak ditemukan.
- Izin dicabut.
- Reconnect berhasil.

## Booking

- Booking valid.
- Booking duplikat.
- Kapasitas penuh.
- Jadwal tidak aktif.
- Member tidak aktif.
- Request bersamaan.
- Request dikirim ulang.
- Booking dibatalkan.

## Dashboard

- Tidak ada data.
- Data tersedia.
- Filter hari ini.
- Filter 7 hari.
- Filter 30 hari.
- Custom date.
- Integrasi terputus.
- Cache kedaluwarsa.

# 17. Definition of Done

Sebuah fitur hanya boleh dinyatakan selesai jika:

1. Implementasi sesuai PRD.
2. Validasi input tersedia.
3. Permission diperiksa backend.
4. Tenant isolation dipastikan.
5. Error handling tersedia.
6. Unit test sesuai kebutuhan.
7. Integration test sesuai kebutuhan.
8. Tidak ada secret di client.
9. Dokumentasi diperbarui.
10. Hasil pengujian dilaporkan.

Jangan menandai fitur selesai hanya karena UI telah dibuat.

# 18. Instruksi Kerja untuk AI Coding Agent

Sebelum mulai coding:

1. Baca PRD.md.
2. Baca TECHNICAL_DOCUMENTATION.md.
3. Periksa struktur repository.
4. Identifikasi teknologi yang sudah ada.
5. Laporkan kondisi project.
6. Buat rencana implementasi bertahap.
7. Identifikasi risiko dan kebutuhan yang belum diputuskan.
8. Jangan langsung mengubah seluruh project.

Saat implementasi:
- Kerjakan satu fase dalam satu waktu.
- Jangan melewati Phase 0.
- Jangan membuat fitur tambahan tanpa persetujuan.
- Jangan mengubah arsitektur tanpa alasan dan persetujuan.
- Gunakan data uji yang jelas terpisah dari data produksi.
- Berikan ringkasan file yang dibuat atau diubah.
- Laporkan pengujian yang benar-benar dijalankan.
- Laporkan keterbatasan yang belum terselesaikan.

## Format Laporan Setelah Setiap Fase

```text
PHASE:
STATUS:

IMPLEMENTED:
- ...

FILES CREATED:
- ...

FILES MODIFIED:
- ...

TESTS EXECUTED:
- ...

TEST RESULTS:
- ...

KNOWN ISSUES:
- ...

SECURITY CONSIDERATIONS:
- ...

NEXT PHASE:
- ...
```

---

# 19. Prinsip Akhir

GymSlot MVP harus mengutamakan:

1. Kesederhanaan arsitektur.
2. Biaya operasional rendah.
3. Keamanan identitas dan data.
4. Isolasi data antar-gym.
5. Keakuratan booking.
6. Kemudahan penggunaan.
7. Dokumentasi yang konsisten.

Google Sheets digunakan sebagai penyimpanan operasional, bukan sebagai pengganti seluruh fungsi backend. Google Apps Script tetap bertanggung jawab menjalankan validasi, otorisasi, dan business logic.

Jika keterbatasan Apps Script atau Sheets menyebabkan kebutuhan keamanan, konsistensi, atau performa tidak dapat dipenuhi, AI agent harus melaporkannya secara transparan dan tidak menyembunyikan risiko tersebut.