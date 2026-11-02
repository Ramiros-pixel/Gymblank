/**
 * settings.gs
 * Konfigurasi environment GymSlot. Bisa diubah antar Development/Staging/Production.
 * Jangan letakkan secret (refresh token, client secret) di file ini.
 *
 * Nilai yang wajib diisi saat deploy (bukan di commit):
 *   Settings.setGoogleClientId('<CLIENT_ID>')
 *   Settings.setGoogleClientSecret('<CLIENT_SECRET>')
 *   Settings.setControlSpreadsheetId('<SHEET_ID>')
 */

var Settings = (function () {
  var props = PropertiesService.getScriptProperties();

  var PREFIX = 'gymslot.';

  function get(key) {
    return props.getProperty(PREFIX + key);
  }

  function set(key, value) {
    if (value === null || value === undefined) {
      props.deleteProperty(PREFIX + key);
    } else {
      props.setProperty(PREFIX + key, String(value));
    }
  }

  return {
    /** Google OAuth 2.0 Client ID untuk login & integrasi Drive/Sheets. */
    getGoogleClientId: function () { return get('google_client_id'); },
    setGoogleClientId: function (v) { set('google_client_id', v); },

    /** Client secret dipakai alur authorization-code. Disimpan di ScriptProperties (PoC). */
    getGoogleClientSecret: function () { return get('google_client_secret'); },
    setGoogleClientSecret: function (v) { set('google_client_secret', v); },

    /** ID Control Spreadsheet (GymSlot_Control). */
    getControlSpreadsheetId: function () { return get('control_spreadsheet_id'); },
    setControlSpreadsheetId: function (v) { set('control_spreadsheet_id', v); },

    /** URL Web App yang dipakai OAuth redirect / callback. */
    getWebAppUrl: function () { return get('web_app_url'); },
    setWebAppUrl: function (v) { set('web_app_url', v); },

    /** Environment: development | staging | production. */
    getEnvironment: function () { return get('environment') || 'development'; },
    setEnvironment: function (v) { set('environment', v); },
  };
})();