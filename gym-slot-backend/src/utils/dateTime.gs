/**
 * dateTime.gs
 * Helper format tanggal dan waktu. Gunakan ISO 8601 dengan offset eksplisit
 * untuk pertukaran data. Zona waktu tampilan mengikuti pengaturan gym.
 */

var DateTimeHelper = (function () {
  /**
   * Mengembalikan timestamp sekarang dalam format ISO 8601.
   * Apps Script timezone mengikuti properti script (Asia/Jakarta).
   */
  function nowIso() {
    return new Date().toISOString();
  }

  /**
   * Mengembalikan Date sekarang.
   */
  function now() {
    return new Date();
  }

  return {
    nowIso: nowIso,
    now: now,
  };
})();