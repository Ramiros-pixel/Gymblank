/**
 * lock.gs
 * Wrapper untuk ScriptLock guna mencegah race condition pada booking.
 * Untuk MVP, menggunakan lock global (cukup untuk skala kecil).
 */

var Lock = (function () {
  /**
   * Mengambil lock global.
   * @param {number} timeoutMs - timeout dalam milidetik.
   * @returns {LockServiceLock}
   */
  function getLock(timeoutMs) {
    return LockService.getScriptLock().tryLock(timeoutMs || 10000);
  }

  /** Melepaskan lock. */
  function releaseLock(lock) {
    if (lock) {
      lock.releaseLock();
    }
  }

  return {
    getLock: getLock,
    releaseLock: releaseLock,
  };
})();
