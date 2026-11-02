/**
 * userService.gs
 * Service pengguna: membuat/memperbarui user dari klaim Google yang tervalidasi,
 * dan mencari user. Identitas final memakai google_sub (bukan email).
 */

var UserService = (function () {
  /**
   * Membuat atau memperbarui user dari klaim Google yang sudah divalidasi backend.
   * @param {Object} claims - hasil GoogleAuth.validateIdToken.
   * @returns {Object} {user, is_new}
   */
  function upsertFromGoogle(claims) {
    if (!claims || !claims.sub) {
      throw Error('AUTH_INVALID');
    }

    var existing = ControlRepository.findOne('Users', { google_sub: claims.sub });

    if (existing && existing.user_id) {
      // Update data profil yang boleh berubah.
      var updated = {
        email: claims.email || existing.email,
        full_name: claims.name || existing.full_name,
        photo_url: claims.picture || existing.photo_url,
        updated_at: DateTimeHelper.nowIso(),
      };
      updateUser(existing.user_id, updated);
      return { user: merge(existing, updated), is_new: false };
    }

    // User baru.
    var userId = Uuid.v4();
    var now = DateTimeHelper.nowIso();
    var user = {
      user_id: userId,
      google_sub: claims.sub,
      email: claims.email || '',
      full_name: claims.name || '',
      photo_url: claims.picture || '',
      account_status: 'Active',
      created_at: now,
      updated_at: now,
    };
    ControlRepository.insertRow('Users', user);
    return { user: user, is_new: true };
  }

  /** Memperbarui kolom user yang diizinkan pada baris yang sudah ada. */
  function updateUser(userId, fields) {
    // PoC sederhana: cari baris dan tulis ulang kolom yang berubah.
    var sheet = ControlRepository.getSheet('Users');
    var headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
    var data = sheet.getDataRange().getValues();
    for (var i = 1; i < data.length; i++) {
      var idIdx = headers.indexOf('user_id');
      if (idIdx >= 0 && String(data[i][idIdx]) === String(userId)) {
        for (var f in fields) {
          var col = headers.indexOf(f);
          if (col >= 0) {
            sheet.getRange(i + 1, col + 1).setValue(fields[f]);
          }
        }
        break;
      }
    }
  }

  function findByUserId(userId) {
    return ControlRepository.findOne('Users', { user_id: userId });
  }

  /** Menggabungkan objek (untuk nilai default). */
  function merge(base, over) {
    var out = {};
    for (var k in base) out[k] = base[k];
    for (var k2 in over) out[k2] = over[k2];
    return out;
  }

  return {
    upsertFromGoogle: upsertFromGoogle,
    findByUserId: findByUserId,
  };
})();