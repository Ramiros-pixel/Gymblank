/**
 * tenantResolver.gs
 * Middleware: menentukan gym aktif dan memverifikasi akses pengguna.
 * TIDAK mempercayai gym_id dari Flutter sebagai bukti akses.
 * Belum diimplementasikan di Phase 0 (masuk Phase 1).
 */

var TenantResolver = (function () {
  /**
   * Mengembalikan spreadsheet ID gym yang sah untuk user.
   * @throws {Error} TENANT_ACCESS_DENIED jika user tidak punya akses.
   */
  function resolveSpreadsheetId(userId, requestedGymId) {
    throw Error('NOT_IMPLEMENTED');
  }

  return { resolveSpreadsheetId: resolveSpreadsheetId };
})();