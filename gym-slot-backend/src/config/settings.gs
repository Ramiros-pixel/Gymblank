/**
 * settings.gs
 * Konfigurasi yang bisa berubah antar environment.
 * Jangan hardcode secret di constants.gs.
 */

var Settings = (function () {
  /**
   * Mengambil ID Control Spreadsheet dari ScriptProperties.
   * Setup sekali oleh admin menggunakan setup_control.gs.
   */
  function getControlSpreadsheetId() {
    return PropertiesService.getScriptProperties()
      .getProperty('CONTROL_SPREADSHEET_ID');
  }

  /**
   * Mengatur ID Control Spreadsheet.
   * Panggil sekali setelah spreadsheet dibuat.
   */
  function setControlSpreadsheetId(id) {
    PropertiesService.getScriptProperties()
      .setProperty('CONTROL_SPREADSHEET_ID', id);
  }

  /**
   * Mengambil Google OAuth Client ID.
   * Harus sama dengan client ID yang digunakan Flutter.
   */
  function getGoogleClientId() {
    return PropertiesService.getScriptProperties()
      .getProperty('GOOGLE_CLIENT_ID');
  }

  /**
   * Mengatur Google OAuth Client ID.
   */
  function setGoogleClientId(clientId) {
    PropertiesService.getScriptProperties()
      .setProperty('GOOGLE_CLIENT_ID', clientId);
  }

  /**
   * Mengambil Google OAuth Client Secret.
   * Dibutuhkan untuk token exchange (authorization code flow).
   */
  function getGoogleClientSecret() {
    return PropertiesService.getScriptProperties()
      .getProperty('GOOGLE_CLIENT_SECRET');
  }

  /**
   * Mengatur Google OAuth Client Secret.
   * Simpan hanya di ScriptProperties, tidak di source code.
   */
  function setGoogleClientSecret(clientSecret) {
    PropertiesService.getScriptProperties()
      .setProperty('GOOGLE_CLIENT_SECRET', clientSecret);
  }

  /**
   * Mengambil Web App URL (untuk OAuth callback).
   */
  function getWebAppUrl() {
    return PropertiesService.getScriptProperties()
      .getProperty('WEB_APP_URL');
  }

  /**
   * Mengatur Web App URL.
   */
  function setWebAppUrl(url) {
    PropertiesService.getScriptProperties()
      .setProperty('WEB_APP_URL', url);
  }

  /**
   * Mengambil OAuth access token.
   */
  function getOAuthAccessToken() {
    return PropertiesService.getScriptProperties()
      .getProperty('OAUTH_ACCESS_TOKEN');
  }

  /**
   * Mengatur OAuth access token.
   */
  function setOAuthAccessToken(token) {
    PropertiesService.getScriptProperties()
      .setProperty('OAUTH_ACCESS_TOKEN', token);
  }

  /**
   * Mengambil OAuth refresh token.
   */
  function getOAuthRefreshToken() {
    return PropertiesService.getScriptProperties()
      .getProperty('OAUTH_REFRESH_TOKEN');
  }

  /**
   * Mengatur OAuth refresh token.
   * PERINGATAN: ScriptProperties bukan Secret Manager khusus.
   * Evaluasi risiko untuk produksi.
   */
  function setOAuthRefreshToken(token) {
    PropertiesService.getScriptProperties()
      .setProperty('OAUTH_REFRESH_TOKEN', token);
  }

  /**
   * Mengatur access token, refresh token, dan expires_at sekaligus.
   */
  function setOAuthTokens(accessToken, refreshToken, expiresAt) {
    setOAuthAccessToken(accessToken);
    setOAuthRefreshToken(refreshToken || '');
    if (expiresAt) {
      PropertiesService.getScriptProperties()
        .setProperty('OAUTH_EXPIRES_AT', String(expiresAt));
    }
  }

  /**
   * Menghapus semua token OAuth (disconnect).
   */
  function clearOAuthTokens() {
    var props = PropertiesService.getScriptProperties();
    props.deleteProperty('OAUTH_ACCESS_TOKEN');
    props.deleteProperty('OAUTH_REFRESH_TOKEN');
    props.deleteProperty('OAUTH_EXPIRES_AT');
  }

  /**
   * Mengecek apakah token masih berlaku.
   */
  function isTokenValid() {
    var expiresAt = PropertiesService.getScriptProperties()
      .getProperty('OAUTH_EXPIRES_AT');
    if (!expiresAt) return false;
    return Number(expiresAt) > Date.now();
  }

  return {
    getControlSpreadsheetId: getControlSpreadsheetId,
    setControlSpreadsheetId: setControlSpreadsheetId,
    getGoogleClientId: getGoogleClientId,
    setGoogleClientId: setGoogleClientId,
    getGoogleClientSecret: getGoogleClientSecret,
    setGoogleClientSecret: setGoogleClientSecret,
    getWebAppUrl: getWebAppUrl,
    setWebAppUrl: setWebAppUrl,
    getOAuthAccessToken: getOAuthAccessToken,
    setOAuthAccessToken: setOAuthAccessToken,
    getOAuthRefreshToken: getOAuthRefreshToken,
    setOAuthRefreshToken: setOAuthRefreshToken,
    setOAuthTokens: setOAuthTokens,
    clearOAuthTokens: clearOAuthTokens,
    isTokenValid: isTokenValid,
  };
})();
