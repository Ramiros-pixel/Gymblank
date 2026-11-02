# GymSlot Backend (Google Apps Script)

Backend API GymSlot berbasis Google Apps Script, dengan Google Sheets sebagai
penyimpanan operasional. Lihat `../TECHNICAL_DOCUMENTATION.md` untuk arsitektur lengkap.

## Status

Phase 0 (Technical Feasibility). Sudah ada PoC autentikasi (auth.google) dan akses
Control Sheet. Belum ada: gym onboarding, OAuth Drive atas nama Owner (Phase 2), dan
semua fitur operasional.

## Struktur

```
src/
  entry/         doGet.gs, doPost.gs
  config/        constants.gs, settings.gs
  core/          router.gs, response.gs, errors.gs, validator.gs
  auth/          googleAuth.gs, session.gs
  middleware/    authentication.gs, authorization.gs, tenantResolver.gs
  services/      userService.gs, gymService.gs, googleDriveService.gs, ...
  repositories/  controlRepository.gs
  utils/         uuid.gs, dateTime.gs, lock.gs, logger.gs
```

## Menyiapkan PoC

1. Buat project Apps Script (atau pasang clasp: `npm i -g @google/clasp`).
2. Push file di folder ini.
3. Buat Control Spreadsheet `GymSlot_Control` dan isi header (lihat script setup di
   `scripts/setup_control.gs`), lalu jalankan script setup untuk membuat tab.
4. Atur Script Properties (via `Settings` atau menu Script Properties):
   - `gymslot.google_client_id` = <OAuth Client ID>
   - `gymslot.google_client_secret` = <client secret> (hanya PoC)
   - `gymslot.control_spreadsheet_id` = <ID Control Sheet>
   - `gymslot.web_app_url` = <URL Web App>
5. Deploy sebagai Web App. Catat deployment ID dan versi.
6. Uji health: GET `?action=health`.

## Catatan keamanan

- Refresh token/secret disimpan di ScriptProperties (PoC). Ini BUKAN solusi produksi;
  evaluasi secret storage sebelum rilis (lihat docs.md K3).
- Access token tidak dikirim lewat URL; token dibawa dalam body JSON.
- Header `Authorization` tidak diandalkan karena keterbatasan Apps Script.