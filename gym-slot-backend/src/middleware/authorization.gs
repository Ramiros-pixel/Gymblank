/**
 * authorization.gs
 * Middleware: pemeriksaan role/permission per gym.
 * Belum diimplementasikan di Phase 0 (masuk Phase 1 Foundation).
 * File ini hanya kerangka; jangan dipanggil oleh handler yang aktif.
 */

var Authorization = (function () {
  /**
   * Memeriksa apakah user memiliki role tertentu pada gym.
   * @throws {Error} PERMISSION_DENIED jika tidak.
   */
  function requireRole(userId, gymId, allowedRoles) {
    throw Error('NOT_IMPLEMENTED');
  }

  return { requireRole: requireRole };
})();