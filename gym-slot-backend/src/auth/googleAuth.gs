/**
 * googleAuth.gs
 * Validasi Google ID token dari Google Sign-In.
 *
 * PoC: memakai endpoint tokeninfo Google untuk membuktikan alur.
 * Produksi: ganti dengan verifikasi signature JWT (lihat TECHNICAL_DOCUMENTATION 6.1).
 *
 * PRINSIP: jangan pernah mempercayai email/role dari Flutter. Identitas final
 * didapat dari klaim `sub` setelah token divalidasi di backend.
 */

var GoogleAuth = (function () {
  var TOKENINFO_URL = 'https://oauth2.googleapis.com/tokeninfo?id_token=';

  /**
   * Memvalidasi ID token dan mengembalikan klaim pengguna yang terverifikasi.
   * @param {string} idToken - ID token dari Google Sign-In.
   * @returns {Object} {sub, email, email_verified, name, picture, aud, exp}
   * @throws {Error} dengan kode AUTH_INVALID jika token tidak valid.
   */
  function validateIdToken(idToken) {
    if (!idToken || typeof idToken !== 'string') {
      throw Error('AUTH_INVALID');
    }

    var response = UrlFetchApp.fetch(TOKENINFO_URL + encodeURIComponent(idToken), {
      muteHttpExceptions: true,
    });

    if (response.getResponseCode() !== 200) {
      throw Error('AUTH_INVALID');
    }

    var claims = JSON.parse(response.getContentText());

    // Validasi audience harus cocok dengan OAuth Client ID GymSlot.
    var expectedAud = Settings.getGoogleClientId();
    if (expectedAud && claims.aud && claims.aud !== expectedAud) {
      throw Error('AUTH_INVALID');
    }

    // Validasi issuer (Google).
    if (claims.iss && claims.iss.indexOf('accounts.google.com') === -1 && claims.iss.indexOf('https://accounts.google.com') === -1) {
      throw Error('AUTH_INVALID');
    }

    // Validasi masa berlaku.
    if (claims.exp && Number(claims.exp) < Math.floor(Date.now() / 1000)) {
      throw Error('AUTH_EXPIRED');
    }

    // `sub` wajib ada.
    if (!claims.sub) {
      throw Error('AUTH_INVALID');
    }

    return {
      sub: claims.sub,
      email: claims.email || '',
      email_verified: claims.email_verified === true || claims.email_verified === 'true',
      name: claims.name || '',
      picture: claims.picture || '',
      aud: claims.aud || '',
      exp: claims.exp ? Number(claims.exp) : 0,
    };
  }

  return {
    validateIdToken: validateIdToken,
  };
})();