/**
 * rateLimiter.gs
 * Rate limiting per user + per action (TECHDOC 5.5, PRD 17: rate limiting).
 *
 * Penyimpanan: CacheService (60 menit, cukup untuk window penilaian).
 * Format counter: rate:<userId>:<action>:<bucket> = jumlah hit.
 * Bucket = menit saat ini → window rata 60 detik.
 *
 * Batas default:
 * - auth.google    : 5 / menit   (login, mahal + validasi token eksternal)
 * - bookings.create: 10 / menit  (proteksi double-tap dan abuse)
 * - default        : 30 / menit  (aktivitas normal aman)
 *
 * Kesalahan menghasilkan RATE_LIMITED (dipetakan di router mapErrorCode).
 */

var RateLimiter = (function () {
  var DEFAULT_LIMITS = {
    'auth.google': 5,
    'bookings.create': 10,
  };
  var DEFAULT_LIMIT = 30;
  var TTL_SECONDS = 120;

  function limitFor(action) {
    if (DEFAULT_LIMITS.hasOwnProperty(action)) return DEFAULT_LIMITS[action];
    return DEFAULT_LIMIT;
  }

  function currentBucket() {
    return String(Math.floor(Date.now() / 60000));
  }

  /**
   * Cek dan catat satu permintaan.
   * @param {string} userId - ID pengguna (bisa kosong untuk anonim).
   * @param {string} action - nama action.
   * @returns {boolean} true jika diizinkan, false jika melebihi batas.
   */
  function check(userId, action) {
    var cache = CacheService.getScriptCache();
    var key = 'rate:' + (userId || 'anon') + ':' + action + ':' + currentBucket();
    var raw = cache.get(key);
    var count = raw ? Number(raw) : 0;
    if (count >= limitFor(action)) {
      return false;
    }
    cache.put(key, String(count + 1), TTL_SECONDS);
    return true;
  }

  return {
    check: check,
    limitFor: limitFor,
  };
})();
