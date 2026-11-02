/**
 * session.gs
 * Session aplikasi GymSlot yang diterbitkan backend setelah ID token divalidasi.
 *
 * Persyaratan (TECHNICAL_DOCUMENTATION 6.2):
 * - Punya masa berlaku.
 * - Punya identitas pengguna.
 * - Tidak memberikan akses lintas-gym secara otomatis.
 * - Dapat dicabut.
 * - Tidak disimpan sebagai data publik.
 * - Tidak menggunakan ID token Google sebagai session permanen.
 *
 * PoC: session disimpan di ScriptProperties (bukan di tab spreadsheet publik).
 * Catatan keamanan: ScriptProperties bukan secret store ideal; evaluasi untuk
 * produksi (lihat Kendala K3 di docs.md).
 */

var Session = (function () {
  var props = PropertiesService.getScriptProperties();
  var PREFIX = 'gymslot.session.';

  function token() {
    // Session token acak. Jangan pernah memakai ID token Google sebagai session.
    return Uuid.v4() + Uuid.v4();
  }

  function key(sessionToken) {
    return PREFIX + sessionToken;
  }

  /**
   * Membuat session baru untuk user.
   * @param {string} userId - user_id dari Control Sheet.
   * @param {number} ttlMs - masa berlaku.
   * @returns {Object} {token, expires_at, user_id}
   */
  function create(userId, ttlMs) {
    var t = token();
    var now = Date.now();
    var ttl = ttlMs || Constants.SESSION_TTL_MS;
    var expiresAt = now + ttl;
    props.setProperty(key(t), JSON.stringify({
      user_id: userId,
      expires_at: expiresAt,
      created_at: now,
    }));
    return {
      token: t,
      expires_at: expiresAt,
      user_id: userId,
    };
  }

  /**
   * Memvalidasi session token.
   * @returns {Object|null} {user_id, expires_at} jika valid, null jika tidak/kedaluwarsa.
   */
  function validate(sessionToken) {
    if (!sessionToken || typeof sessionToken !== 'string') return null;
    var raw = props.getProperty(key(sessionToken));
    if (!raw) return null;
    var data;
    try {
      data = JSON.parse(raw);
    } catch (e) {
      return null;
    }
    if (!data.user_id || !data.expires_at) return null;
    if (Number(data.expires_at) < Date.now()) {
      props.deleteProperty(key(sessionToken));
      return null;
    }
    return data;
  }

  /** Mencabut session. */
  function revoke(sessionToken) {
    if (sessionToken) props.deleteProperty(key(sessionToken));
  }

  return {
    create: create,
    validate: validate,
    revoke: revoke,
  };
})();