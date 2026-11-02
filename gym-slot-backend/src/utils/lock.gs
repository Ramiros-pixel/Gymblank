/**
 * lock.gs
 * Pembungkus LockService untuk operasi yang harus atomik (booking).
 *
 * CATATAN (lihat TECHNICAL_DOCUMENTATION 8.1):
 * - ScriptLock memakai kunci global pada deployment yang sama, jadi operasi
 *   dari seluruh gym dapat saling menunggu. Aman secara sederhana tapi
 *   mengurangi throughput.
 * - LockService BUKAN transaksi database penuh.
 * - Jangan klaim sistem aman hanya karena sudah memakai lock; perlu uji
 *   konkurensi (Phase 4/7).
 */

var Lock = (function () {
  var DEFAULT_TIMEOUT_MS = 30000;

  /**
   * Menjalankan fungsi di dalam lock.
   * @param {function} fn - fungsi yang dijalankan dalam lock.
   * @param {number} timeoutMs - waktu tunggu memperoleh lock.
   * @returns {*} hasil fn.
   */
  function withLock(fn, timeoutMs) {
    var lock = LockService.getScriptLock();
    var timeout = timeoutMs || DEFAULT_TIMEOUT_MS;
    var got = lock.tryLock(timeout);
    if (!got) {
      throw Error('Could not acquire script lock within ' + timeout + 'ms');
    }
    try {
      return fn();
    } finally {
      lock.releaseLock();
    }
  }

  return {
    withLock: withLock,
  };
})();