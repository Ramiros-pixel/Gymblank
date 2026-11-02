/**
 * response.gs
 * Format respons standar GymSlot.
 *
 * Berhasil:
 *   { success: true, request_id, data, message }
 *
 * Gagal:
 *   { success: false, request_id, error: { code, message } }
 *
 * Jangan pernah mengirim stack trace, token, atau informasi internal ke klien.
 */

var Response = (function () {
  /**
   * Membuat respons sukses.
   * @param {string} requestId - ID request yang dikirim klien.
   * @param {*} data - Data hasil.
   * @param {string} message - Pesan singkat.
   */
  function ok(requestId, data, message) {
    return {
      success: true,
      request_id: requestId,
      data: data || null,
      message: message || 'Request berhasil',
    };
  }

  /**
   * Membuat respons gagal.
   * @param {string} requestId - ID request (bisa kosong jika belum ada).
   * @param {string} code - Kode error terstandar (lihat errors.gs).
   * @param {string} message - Pesan ramah untuk pengguna.
   */
  function fail(requestId, code, message) {
    return {
      success: false,
      request_id: requestId,
      error: {
        code: code,
        message: message,
      },
    };
  }

  return {
    ok: ok,
    fail: fail,
  };
})();