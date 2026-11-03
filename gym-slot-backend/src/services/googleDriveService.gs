/**
 * googleDriveService.gs
 * Service integrasi Google Drive/Sheets atas nama Owner.
 * Milik Phase 0 (PoC OAuth) dan Phase 2 (Gym Onboarding).
 *
 * PRINSIP: spreadsheet dibuat di Drive Owner, bukan akun operator.
 * Ini membutuhkan OAuth authorization-code flow atas nama Owner.
 *
 * Implementasi ini menyediakan struktur alur OAuth. Untuk produksi,
 * gunakan library OAuth2 resmi untuk Google Apps Script dan evaluasi
 * penyimpanan refresh token secara aman (lihat settings.gs).
 */

var GoogleDriveService = (function () {
  var SCOPES = [
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/spreadsheets',
  ];

  /**
   * Mendapatkan URL autorisasi OAuth untuk Owner.
   * Flutter akan membuka URL ini di browser, Owner memberikan izin,
   * lalu Google akan mengarahkan kembali ke callback URL Apps Script.
   * @param {string} ownerUserId - ID user owner.
   * @param {string} state - state parameter untuk CSRF protection.
   * @returns {string} URL autorisasi.
   */
  function getAuthorizationUrl(ownerUserId, state) {
    var clientId = Settings.getGoogleClientId();
    if (!clientId) {
      throw Error('GOOGLE_CLIENT_ID_NOT_CONFIGURED');
    }
    var redirectUri = getCallbackUrl();
    var params = {
      client_id: clientId,
      redirect_uri: redirectUri,
      scope: SCOPES.join(' '),
      response_type: 'code',
      access_type: 'offline',
      prompt: 'consent',
      state: state || '',
    };
    var qs = Object.keys(params)
      .map(function (k) { return k + '=' + encodeURIComponent(params[k]); })
      .join('&');
    return 'https://accounts.google.com/o/oauth2/v2/auth?' + qs;
  }

  /**
   * Menangani callback OAuth dari Google.
   * Menerima authorization code, menukar dengan access token dan refresh token,
   * lalu menyimpannya melalui Settings.
   * @param {string} code - Authorization code dari Google.
   * @returns {Object} {integrationId, accessToken, refreshToken, expiresAt}
   */
  function handleCallback(code) {
    var clientId = Settings.getGoogleClientId();
    var clientSecret = Settings.getGoogleClientSecret();
    if (!clientId || !clientSecret) {
      throw Error('GOOGLE_OAUTH_NOT_CONFIGURED');
    }
    var redirectUri = getCallbackUrl();

    var response = UrlFetchApp.fetch('https://oauth2.googleapis.com/token', {
      method: 'post',
      muteHttpExceptions: true,
      contentType: 'application/x-www-form-urlencoded',
      payload: {
        code: code,
        client_id: clientId,
        client_secret: clientSecret,
        redirect_uri: redirectUri,
        grant_type: 'authorization_code',
      },
    });

    if (response.getResponseCode() !== 200) {
      throw Error('GOOGLE_OAUTH_TOKEN_EXCHANGE_FAILED');
    }

    var tokenData = JSON.parse(response.getContentText());
    var now = Date.now();
    var expiresAt = now + (tokenData.expires_in || 3600) * 1000;

    Settings.setOAuthTokens(tokenData.access_token, tokenData.refresh_token, expiresAt);

    return {
      accessToken: tokenData.access_token,
      refreshToken: tokenData.refresh_token,
      expiresAt: expiresAt,
    };
  }

  /**
   * Membuat spreadsheet GymBooking di Drive Owner.
   * Memerlukan access token yang valid.
   * @param {string} ownerUserId - ID user owner.
   * @param {string} gymId - ID gym.
   * @param {string} accessToken - OAuth access token.
   * @returns {Object} {spreadsheetId, spreadsheetUrl}
   */
  function createGymSpreadsheet(ownerUserId, gymId, accessToken) {
    if (!accessToken) {
      throw Error('GOOGLE_DISCONNECTED');
    }

    // Membuat spreadsheet via Google Drive API (akses atas nama Owner)
    var createResponse = UrlFetchApp.fetch('https://www.googleapis.com/drive/v3/files', {
      method: 'post',
      muteHttpExceptions: true,
      headers: { Authorization: 'Bearer ' + accessToken },
      contentType: 'application/json',
      payload: JSON.stringify({
        name: 'GymBooking',
        mimeType: 'application/vnd.google-apps.spreadsheet',
      }),
    });

    if (createResponse.getResponseCode() !== 200) {
      throw Error('GOOGLE_DRIVE_CREATE_FAILED');
    }

    var fileData = JSON.parse(createResponse.getContentText());
    var spreadsheetId = fileData.id;

    // Membuat tab dan header via Google Sheets API
    var tabs = Constants.GYM_TABS;
    var headersMap = Constants.GYM_HEADERS;

    // Rename default sheet ke 'Dashboard' dan sisipkan tab lainnya
    var batchUpdate = {
      requests: [],
    };

    // Rename sheet pertama (default 'Sheet1') ke 'Dashboard'
    var sheetsResponse = UrlFetchApp.fetch(
      'https://sheets.googleapis.com/v4/spreadsheets/' + spreadsheetId,
      { method: 'get', muteHttpExceptions: true, headers: { Authorization: 'Bearer ' + accessToken } }
    );
    if (sheetsResponse.getResponseCode() === 200) {
      var sheetsData = JSON.parse(sheetsResponse.getContentText());
      var firstSheetId = sheetsData.sheets[0].properties.sheetId;
      batchUpdate.requests.push({
        updateSheetProperties: {
          properties: { sheetId: firstSheetId, title: 'Dashboard' },
          fields: 'title',
        },
      });
    }

    // Tambahkan tab lain (kecuali Dashboard yang sudah ada)
    for (var i = 0; i < tabs.length; i++) {
      if (tabs[i] === 'Dashboard') continue;
      batchUpdate.requests.push({
        addSheet: { properties: { title: tabs[i] } },
      });
    }

    if (batchUpdate.requests.length > 0) {
      UrlFetchApp.fetch(
        'https://sheets.googleapis.com/v4/spreadsheets/' + spreadsheetId + ':batchUpdate',
        {
          method: 'post',
          muteHttpExceptions: true,
          headers: { Authorization: 'Bearer ' + accessToken },
          contentType: 'application/json',
          payload: JSON.stringify(batchUpdate),
        }
      );
    }

    // Tulis header ke setiap tab
    for (var i = 0; i < tabs.length; i++) {
      var tabName = tabs[i];
      var headers = headersMap[tabName];
      if (!headers) continue;
      var range = tabName + '!A1:' + String.fromCharCode(65 + headers.length - 1) + '1';
      UrlFetchApp.fetch(
        'https://sheets.googleapis.com/v4/spreadsheets/' + spreadsheetId + '/values/' + encodeURIComponent(range) + ':append',
        {
          method: 'post',
          muteHttpExceptions: true,
          headers: { Authorization: 'Bearer ' + accessToken },
          contentType: 'application/json',
          payload: JSON.stringify({ values: [headers] }),
        }
      );
    }

    // Simpan metadata integrasi ke Control Spreadsheet
    ControlRepository.insertRow('Integrations', {
      integration_id: Uuid.v4(),
      gym_id: gymId,
      provider: 'google_drive',
      status: 'Connected',
      token_ref_expires_at: new Date(Date.now() + 3600 * 1000).toISOString(),
      connected_at: new Date().toISOString(),
      last_error: '',
    });

    return {
      spreadsheetId: spreadsheetId,
      spreadsheetUrl: 'https://docs.google.com/spreadsheets/d/' + spreadsheetId,
    };
  }

  /**
   * Mengecek status koneksi Google Drive/Sheets.
   * @returns {Object} {connected, status, lastError}
   */
  function getConnectionStatus() {
    var accessToken = Settings.getOAuthAccessToken();
    if (!accessToken) {
      return { connected: false, status: 'Disconnected', lastError: 'Tidak ada token akses' };
    }
    // Coba panggil API sederhana untuk verifikasi token
    try {
      var response = UrlFetchApp.fetch('https://www.googleapis.com/drive/v3/about?fields=user', {
        method: 'get',
        muteHttpExceptions: true,
        headers: { Authorization: 'Bearer ' + accessToken },
      });
      if (response.getResponseCode() === 200) {
        return { connected: true, status: 'Connected', lastError: '' };
      }
      return { connected: false, status: 'Error', lastError: 'Token tidak valid' };
    } catch (e) {
      return { connected: false, status: 'Error', lastError: e.message };
    }
  }

  /**
   * Memutuskan koneksi Google Drive/Sheets.
   */
  function disconnect() {
    Settings.clearOAuthTokens();
  }

  function getCallbackUrl() {
    // Callback URL adalah Web App URL Apps Script dengan action oauth.callback
    return PropertiesService.getScriptProperties().getProperty('WEB_APP_URL') || '';
  }

  return {
    getAuthorizationUrl: getAuthorizationUrl,
    handleCallback: handleCallback,
    createGymSpreadsheet: createGymSpreadsheet,
    getConnectionStatus: getConnectionStatus,
    disconnect: disconnect,
  };
})();

/**
 * Fungsi trigger untuk OAuth callback (dipanggil oleh Google setelah izin).
 * @param {Object} e - event dari Apps Script.
 */
function doGetOAuthCallback(e) {
  var code = e && e.parameter ? e.parameter.code : null;
  var state = e && e.parameter ? e.parameter.state : null;
  if (!code) {
    return ContentService.createTextOutput('Autorisasi gagal: code tidak tersedia.')
      .setMimeType(ContentService.MimeType.TEXT);
  }
  try {
    GoogleDriveService.handleCallback(code);
    return ContentService.createTextOutput('Autorisasi berhasil. Anda dapat kembali ke aplikasi GymSlot.')
      .setMimeType(ContentService.MimeType.TEXT);
  } catch (err) {
    return ContentService.createTextOutput('Autorisasi gagal: ' + err.message)
      .setMimeType(ContentService.MimeType.TEXT);
  }
}
