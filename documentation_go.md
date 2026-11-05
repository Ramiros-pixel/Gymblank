# GymSlot — Dokumentasi Backend Go (Env Golang)

Dokumen ini mencatat backend GymSlot versi **Go** yang berjalan di server ini, cara pakai dua environment (dev/prod), cara integrasi ke Flutter yang sudah ada, serta status deploy akses jarak jauh. Ditulis berdasarkan implementasi dan verifikasi nyata di server (`ramirosservers`) pada sesi kerja ini.

> **Prinsip:** Backend Go ini mempertahankan kontrak API dan cakupan fitur PRD (`PRD.md`). Flutter tetap memakai pola request yang sama (`POST {action, version, request_id, payload, auth}`) sehingga integrasi cukup ganti URL — tanpa mengorbankan fitur yang ada.

---

## 1. Ringkasan

| Item | Nilai |
|---|---|
| Lokasi source | `/srv/Gymblank/gymslot-go/` |
| Lokasi env terpisah | `/srv/Gymblank/gymslot-go-env/{dev,prod}/` |
| Bahasa/runtime | Go 1.26.8 (`go.mod`: module `gymslot`, dep `github.com/go-sql-driver/mysql`) |
| Database | MySQL 8.4 lokal (unix socket default) — **padanan** Google Sheets/Spreadsheet pada arsitektur Apps Script |
| Kontrak API | Identik dengan Apps Script: `POST` JSON `{action,version,request_id,payload,auth}` → `{success,request_id,data,message}` / `{success,request_id,error{code,message}}` |
| Multi-tenant | Satu DB kontrol + **satu database per gym** (di-resolve dari membership di backend; `gym_id`/DB tidak dipercaya dari klien sebagai otoritas) |
| Endpoint publik (prod, via Tailscale Funnel) | `https://ramirosservers.tail2d4b04.ts.net/gymslot` → `127.0.0.1:8091` |

---

## 2. Struktur

```
/srv/Gymblank/
├── gymslot-go/                 # source backend Go (satu codebase)
│   ├── main.go                 # entrypoint: load config → ensure schema → listen
│   ├── config.go               # config dari environment variable
│   ├── db.go                   # koneksi MySQL, schema kontrol + schema per-gym, provisioning DB
│   ├── router.go               # routing by action, validasi, rate limit, auth sesi, tenant resolve
│   ├── auth.go                 # verifikasi Google ID token (fail-closed di prod), sesi, upsert user (google_sub)
│   ├── errors.go               # kode error (paritas dengan Apps Script) + helper respons
│   ├── util.go                 # UUID, waktu ISO, helper
│   ├── services_core.go        # auth/gyms/memberships + helper role/tenant/audit
│   ├── services_data.go        # members, facilities, schedules
│   ├── services_booking.go     # bookings, attendance, settings
│   ├── services_integration.go # integrasi dipetakan ke provisioning DB per-gym (kompatibel Flutter)
│   ├── dashboard.go            # dashboard stats/charts + cache + lock (GET_LOCK)
│   ├── go.mod / go.sum
│   └── gymslot                 # binary hasil build lokal (opsional)
└── gymslot-go-env/             # ENV TERPISAH (tidak mengubah source)
    ├── run.sh                  # build+run per env: ./run.sh <dev|prod>
    ├── dev/
    │   ├── env                 # variabel dev
    │   └── gymslot-dev         # binary dev (hasil build)
    └── prod/
        ├── env                 # variabel prod
        └── gymslot-prod        # binary prod (hasil build)
```

**Kenapa folder terpisah?** Source Go tunggal dipakai bersama; yang berbeda hanya file `env` + binary per environment. Ini memudahkan integrasi bertahap ke Flutter (bisa switch dev/prod/Apps Script) tanpa duplikasi kode dan tanpa mengorbankan fitur.

---

## 3. Environment & Konfigurasi

Semua config via environment variable (tidak ada secret di source). Dibaca di `config.go`:

| Variabel | Default | Keterangan |
|---|---|---|
| `GYMSLOT_PORT` | `8090` | Port listen (bind `127.0.0.1:<port>`) |
| `GYMSLOT_DB` | `gymslot_control` | Nama **database kontrol** (users, gyms, memberships, sessions, integrations, invitations, audit_logs, rate_limits, dashboard_cache) |
| `GYMSLOT_ENV` | `development` | `development` \| `production` |
| `GYMSLOT_GOOGLE_CLIENT_ID` | *(kosong)* | OAuth Client ID untuk validasi Google ID token. **Di production wajib diisi** (validasi fail-closed). |
| `GYMSLOT_DSN` | *(kosong)* | DSN MySQL. Kosong → default `root@unix(/var/run/mysqld/mysqld.sock)/?parseTime=true` (lokal). Contoh TCP: `user:pass@tcp(127.0.0.1:3306)/?parseTime=true` |
| `GYMSLOT_JWT_SECRET` | *(kosong)* | Dicadangkan; sesi saat ini token random tersimpan di DB kontrol. |
| `GYMSLOT_DEV_SUB` / `GYMSLOT_DEV_EMAIL` / `GYMSLOT_DEV_NAME` | dev default | Override identitas dev (hanya relevan saat mode dev + token `dev`). |

### Isi env saat ini

**`/srv/Gymblank/gymslot-go-env/dev/env`**
```env
GYMSLOT_PORT=8090
GYMSLOT_DB=gymslot_dev_control
GYMSLOT_ENV=development
# GOOGLE_CLIENT_ID opsional di dev (token "dev" diterima untuk testing lokal)
# GYMSLOT_GOOGLE_CLIENT_ID=
# GYMSLOT_DSN=  # kosong = root@unix socket lokal
```

**`/srv/Gymblank/gymslot-go-env/prod/env`**
```env
GYMSLOT_PORT=8091
GYMSLOT_DB=gymslot_prod_control
GYMSLOT_ENV=production
# WAJIB di production: isi Google Client ID agar validasi ID token fail-closed
# GYMSLOT_GOOGLE_CLIENT_ID=xxxxxxxxxxxx.apps.googleusercontent.com
# GYMSLOT_DSN=user:pass@tcp(127.0.0.1:3306)/?parseTime=true
```

> **Isolasi data:** dev dan prod memakai database kontrol berbeda (`gymslot_dev_control` vs `gymslot_prod_control`) dan masing-masing membuat database per-gym terpisah — sehingga data dev/prod tidak tercampur.

---

## 4. Menjalankan

```bash
# Build + run salah satu environment (dari mana saja)
/srv/Gymblank/gymslot-go-env/run.sh dev    # listen 127.0.0.1:8090
/srv/Gymblank/gymslot-go-env/run.sh prod   # listen 127.0.0.1:8091

# Build manual
cd /srv/Gymblank/gymslot-go && go build -o /tmp/gymslot ./...
```

`run.sh` akan `source` file `env`, build binary ke folder env terkait, lalu `exec` binary. Server **bind ke loopback** (`127.0.0.1`) — akses publik dilakukan lewat reverse-proxy/Tailscale funnel (bukan expose port langsung).

**Catatan operasional:** Saat ini proses dev/prod dijalankan sebagai background process di sesi server (bukan service persisten lintas reboot). Untuk produksi jangka panjang, disarankan jadikan **systemd service** (template ada di bagian 9) agar auto-start/auto-restart.

---

## 5. Kontrak API & Action (paritas PRD/Apps Script)

- **Method:** `POST` (routing berdasarkan `body.action`, aman di balik proxy dengan prefix path seperti `/gymslot`).
- **Auth token:** dibawa di body (`auth.session_token` / `auth.id_token`), bukan header — konsisten dengan keterbatasan Apps Script dan implementasi `ApiClient` Flutter.
- **Rate limit:** in-memory per IP+action (pra-auth) dan per user untuk action sensitif; over-limit → `RATE_LIMITED` (HTTP 429).
- **Tenant isolation:** route bertanda tenant me-resolve DB per-gym dari **membership backend** (bukan dari payload klien). Akses lintas-tenant ditolak (`TENANT_ACCESS_DENIED`).

Action yang diimplementasikan (setara router Apps Script): `auth.google|me|logout`, `gyms.create|list|detail|update`, `memberships.list`, `integrations.connect|callback|status|create-spreadsheet|disconnect`, `members.list|create|update|deactivate`, `facilities.list|create|update|deactivate`, `schedules.list|create|update|deactivate`, `bookings.list|my|create|cancel`, `attendance.list|checkin`, `settings.get|update`, `dashboard.stats|charts`.

Kode error dipertahankan (antara lain): `AUTH_INVALID`, `AUTH_EXPIRED`, `PERMISSION_DENIED`, `GYM_NOT_FOUND`, `TENANT_ACCESS_DENIED`, `VALIDATION_ERROR`, `DUPLICATE_BOOKING`, `CAPACITY_FULL`, `GOOGLE_DISCONNECTED` (dipakai juga untuk “DB gym belum dibuat”), `RATE_LIMITED`, `INTERNAL_ERROR`, `MEMBER_NOT_FOUND`, `FACILITY_NOT_FOUND`, `SCHEDULE_NOT_FOUND`, `SCHEDULE_CONFLICT`, `BOOKING_NOT_FOUND`.

### Perilaku penting yang dipertahankan (PRD)
- Identitas permanen = `google_sub` (bukan email).
- Booking (PRD 13): cek member/jadwal/fasilitas aktif → duplikat pra-lock → **`GET_LOCK` per-gym** → re-check duplikat + kapasitas **di dalam lock** → insert `Confirmed`. Status pemakai kapasitas: `Pending`,`Confirmed`. Gagal dapat lock → `RATE_LIMITED` (client retry), **tidak pernah** menulis tanpa lock.
- Jadwal: tolak overlap fasilitas sama (`start1 < end2 && end1 > start2`) dan `end_time > start_time`.
- Attendance (PRD 14): gated oleh settings gym, kebijakan `booking_required`/walk-in, satu booking satu check-in, **`check_in_at` selalu waktu server** (bukan device).
- Settings: whitelist key, validasi semua sebelum tulis (all-or-nothing); update `timezone` menginvalidasi cache dashboard.
- Dashboard: “hari ini” = timezone gym (fallback `Asia/Jakarta`); cache TTL ~60 detik; 5 dataset chart.
- Data operasional pakai UUID; isolasi per-gym; audit log (kegagalan audit tidak memutus alur utama).

---

## 6. Perbedaan sengaja vs Backend Apps Script (perlu dipahami)

| Aspek | Apps Script (sebelumnya) | Go (sekarang) |
|---|---|---|
| Penyimpanan operasional | Google Sheets per gym (spreadsheet) | **MySQL: 1 database per gym** (tabel setara tab: members/facilities/schedules/bookings/attendance/settings/audit_logs/dashboard_cache) |
| Integrasi Drive/Sheets | OAuth Drive/Sheets, buat spreadsheet, simpan token (ScriptProperties) | `integrations.*` **dipetakan ke provisioning DB per-gym** (tanpa OAuth Drive). `create-spreadsheet` = pastikan DB+tabel+default settings (idempotent). Kompatibel dengan alur Flutter, tapi **tidak** membuat file Google Sheets. |
| Locking konkurensi | `LockService` | `GET_LOCK` MySQL per gym |
| Cache | `CacheService` (trik generasi) | Tabel `dashboard_cache` (TTL/expiry) + invalidasi |
| Secret/token OAuth | ScriptProperties | Tidak ada token Drive; login Google diverifikasi via `tokeninfo` (perlu `GYMSLOT_GOOGLE_CLIENT_ID` di prod) |

**Implikasi:** Jika kebutuhan produk mengharuskan data operasional tetap berada di Google Sheets/Drive, gunakan backend Apps Script (cukup ganti `GYMSLOT_API_URL`). Backend Go memenuhi fitur PRD pada storage MySQL dan mengurangi ketergantungan/biaya kuota Apps Script+Sheets.

---

## 7. Integrasi Flutter (akses jarak jauh, tanpa ubah fitur)

Flutter sudah membaca URL dari `--dart-define` (`ApiConfig` di `gym_slot/lib/core/network/api_client.dart`) dan mengirim token di body — **tidak ada perubahan logika fitur** yang diperlukan.

### Pilih backend via `GYMSLOT_API_URL`

```bash
# PRODUKSI — backend Go di server ini (publik via funnel)
/path/to/flutter run  (atau: flutter build apk/web ...) \
  --dart-define=GYMSLOT_API_URL=https://ramirosservers.tail2d4b04.ts.net/gymslot \
  --dart-define=GYMSLOT_GOOGLE_CLIENT_ID=<CLIENT_ID_YANG_SAMA_DENGAN_PROD_ENV>

# DEVELOPMENT — backend Go lokal
  --dart-define=GYMSLOT_API_URL=http://127.0.0.1:8090/api \
  --dart-define=GYMSLOT_GOOGLE_CLIENT_ID=<CLIENT_ID>

# FALLBACK — Apps Script (fitur/kontrak tetap)
  --dart-define=GYMSLOT_API_URL=https://script.google.com/macros/s/<DEPLOYMENT_ID>/exec \
  --dart-define=GYMSLOT_GOOGLE_CLIENT_ID=<CLIENT_ID>
```

`ApiClient` memanggil `POST <baseUrl>` dengan body `{action,version,request_id,payload,auth}` — format yang sama diterima backend Go maupun Apps Script.

---

## 8. Deploy Publik (Tailscale Serve + Funnel) — status saat ini

Routing funnel/serve host `ramirosservers.tail2d4b04.ts.net` (terverifikasi):

| Path | Target | Keterangan |
|---|---|---|
| `/` | `127.0.0.1:443` | (sesuai konfigurasi saat pengaktifan funnel; lihat catatan di bawah) |
| `/api` | `127.0.0.1:8000` | iot-mqtt (sudah ada sebelumnya, **jangan ditabrak**) |
| `/monitor` | `127.0.0.1:8099` | srv-monitoring |
| `/gymslot` | `127.0.0.1:8091` | **GymSlot Go prod (Funnel on / publik)** |

Perintah yang dipakai (ringkas, butuh izin serve/funnel):
```bash
sudo tailscale serve --https=443 --set-path=/gymslot --bg 127.0.0.1:8091
sudo tailscale funnel --bg 443   # aktifkan funnel publik
tailscale serve status ; tailscale funnel status
```

**Verifikasi nyata (dari server):**
- `POST https://ramirosservers.tail2d4b04.ts.net/gymslot` `{"action":"auth.google","auth":{"id_token":"dev"},...}` → `{"success":false,"error":{"code":"AUTH_INVALID","message":"Server belum dikonfigurasi GOOGLE_CLIENT_ID"}}`. Ini membuktikan endpoint publik tembus dan **backend Go prod** yang menjawab; penolakan token `dev` adalah perilaku *fail-closed* yang benar (prod belum diisi `GYMSLOT_GOOGLE_CLIENT_ID`).
- Dev lokal `127.0.0.1:8090` menerima token `dev` (development) — terverifikasi sebelumnya via smoke test alur PRD.

**Catatan `/` route:** saat funnel diaktifkan, route `/` terdata ke `127.0.0.1:443` (berbeda dari mapping `/ → 127.0.0.1:3000` yang tercatat di memory proyek). `/gymslot` sudah terverifikasi merespons, namun jika app root lain terdampak, sesuaikan route `/` kembali ke target yang benar secara sengaja (jangan diubah sepihak) agar tidak mengganggu service lain.

---

## 9. Ketahanan Proses (opsional, disarankan) — contoh systemd

Saat ini dev/prod berjalan sebagai proses background. Contoh unit (adaptasi path/user/env sesuai kebutuhan):

```ini
# /etc/systemd/system/gymslot-go-prod.service (contoh — butuh sudo)
[Unit]
Description=GymSlot Go Backend (prod)
After=network.target mysql.service

[Service]
Type=simple
WorkingDirectory=/srv/Gymblank/gymslot-go
EnvironmentFile=/srv/Gymblank/gymslot-go-env/prod/env
ExecStart=/srv/Gymblank/gymslot-go-env/prod/gymslot-prod
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
```

Lalu: `sudo systemctl daemon-reload && sudo systemctl enable --now gymslot-go-prod` (dan unit serupa untuk dev bila diperlukan).

---

## 10. Testing cepat (development)

Mode `development` menerima `auth.id_token = "dev"` (identitas dev default) untuk uji lokal tanpa Google. Contoh:

```bash
# login dev
curl -s -X POST http://127.0.0.1:8090/api -H 'Content-Type: application/json' \
  -d '{"action":"auth.google","version":"v1","request_id":"t1","payload":{},"auth":{"id_token":"dev"}}'
```

Smoke test end-to-end (login → create gym → member/facility/schedule → booking duplikat/konflik → cancel → settings → attendance → dashboard → isolasi tenant) pernah dijalankan terhadap dev dan lulus pada jalur inti PRD (setelah perbaikan bug validasi `request_id`).

---

## 11. Known issues / catatan jujur

1. **`request_id` (sudah diperbaiki):** router awal menolak karakter `.` pada `request_id` (regex ketat) padahal Apps Script tidak membatasinya — menyebabkan request valid ditolak. **Diperbaiki** di `router.go` menjadi pembatasan panjang saja (≤128), sehingga kontrak identik.
2. **Skema DB dibuat tanpa `USE` (sudah diperbaiki):** `db.go` sempat menjalankan `CREATE TABLE` tanpa memilih database → `Error 1046 No database selected`. **Diperbaiki** dengan `USE <db>` di helper eksekusi skema.
3. **Production butuh `GYMSLOT_GOOGLE_CLIENT_ID`:** sampai variabel ini diisi di `gymslot-go-env/prod/env` dan proses prod di-restart, login Google nyata akan ditolak (by design, fail-closed). Token `dev` hanya untuk environment development.
4. **Integrasi = provisioning MySQL, bukan Google Sheets:** fitur PRD terpenuhi pada storage MySQL; bukan replikasi file Google Sheets. Pilih backend sesuai kebutuhan penyimpanan.
5. **Ketersediaan lintas reboot:** proses belum menjadi systemd service; setelah reboot perlu dijalankan lagi (atau pasang unit §9).
6. **Perubahan route `/` pada funnel:** teramati beralih ke `127.0.0.1:443` saat aktivasi; verifikasi layanan di path `/` bila ada yang terdampak.

---

## 12. Referensi

- PRD: `PRD.md`
- Dokumentasi teknis Apps Script: `TECHNICAL_DOCUMENTATION.md`
- Skill implementasi: `~/.hermes/skills/flutter-apps-script-mvp/SKILL.md`, `~/.hermes/skills/gymslot-implementation/SKILL.md`
- Flutter API client: `gym_slot/lib/core/network/api_client.dart` (`ApiConfig.apiUrl` / `GYMSLOT_API_URL`, `GYMSLOT_GOOGLE_CLIENT_ID`)
- URL publik backend Go (prod): `https://ramirosservers.tail2d4b04.ts.net/gymslot`
- Source & env: `/srv/Gymblank/gymslot-go/`, `/srv/Gymblank/gymslot-go-env/`
