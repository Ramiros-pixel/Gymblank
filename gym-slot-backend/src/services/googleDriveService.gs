/**
 * googleDriveService.gs
 * Service integrasi Google Drive/Sheets atas nama Owner.
 * Milik Phase 2 (Gym Onboarding) dan PoC OAuth Phase 0.
 * Belum diimplementasikan. Jangan dipanggil oleh handler aktif.
 *
 * PRINSIP: spreadsheet dibuat di Drive Owner, bukan akun operator.
 * Ini membutuhkan OAuth authorization-code flow atas nama Owner.
 */

var GoogleDriveService = (function () {
  /** Membuat spreadsheet GymBooking di Drive Owner. Belum diimplementasikan. */
  function createGymSpreadsheet(ownerUserId, gymId) {
    throw Error('NOT_IMPLEMENTED');
  }

  return { createGymSpreadsheet: createGymSpreadsheet };
})();