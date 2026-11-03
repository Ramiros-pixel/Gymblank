/**
 * googleIntegrationService.gs
 * Service untuk integrasi Google Drive/Sheets dari sisi handler.
 * Melakukan bridging antara request HTTP dan GoogleDriveService.
 */

var GoogleIntegrationService = (function () {
  /**
   * Mulai alur OAuth: buat URL autorisasi untuk Owner.
   * @param {Object} body - request body dengan payload { owner_user_id }.
   * @returns {Object} { authorizationUrl, state }
   */
  function startConnect(body) {
    var payload = body.payload || {};
    var ownerUserId = payload.owner_user_id;
    if (!ownerUserId) {
      throw Error('VALIDATION_ERROR', 'owner_user_id wajib diisi');
    }

    var state = Uuid.v4();
    // Simpan state sementara untuk validasi callback
    PropertiesService.getScriptProperties()
      .setProperty('oauth.state.' + state, ownerUserId);
    PropertiesService.getScriptProperties()
      .setProperty('oauth.state.' + state + '.ts', String(Date.now()));

    var authUrl = GoogleDriveService.getAuthorizationUrl(ownerUserId, state);
    return { authorizationUrl: authUrl, state: state };
  }

  /**
   * Callback OAuth dari Google (dipanggil via doGet atau doPost action).
   * @param {Object} body - request body dengan payload { code, state }.
   * @returns {Object} { connected, spreadsheetId? }
   */
  function handleCallback(body) {
    var payload = body.payload || {};
    var code = payload.code;
    var state = payload.state;

    if (!code || !state) {
      throw Error('VALIDATION_ERROR', 'code dan state wajib diisi');
    }

    // Validasi state
    var storedOwnerId = PropertiesService.getScriptProperties()
      .getProperty('oauth.state.' + state);
    if (!storedOwnerId) {
      throw Error('VALIDATION_ERROR', 'State tidak valid atau kedaluwarsa');
    }

    // Hapus state setelah digunakan
    PropertiesService.getScriptProperties()
      .deleteProperty('oauth.state.' + state);
    PropertiesService.getScriptProperties()
      .deleteProperty('oauth.state.' + state + '.ts');

    // Tukar code dengan token
    var tokenResult = GoogleDriveService.handleCallback(code);

    // Simpan integrasi ke Control Spreadsheet
    ControlRepository.insertRow('Integrations', {
      integration_id: Uuid.v4(),
      gym_id: payload.gym_id || '',
      provider: 'google_drive',
      status: 'Connected',
      token_ref_expires_at: new Date(tokenResult.expiresAt).toISOString(),
      connected_at: new Date().toISOString(),
      last_error: '',
    });

    return {
      connected: true,
      accessToken: tokenResult.accessToken,
      refreshToken: tokenResult.refreshToken,
      expiresAt: tokenResult.expiresAt,
    };
  }

  /**
   * Cek status koneksi Google Drive/Sheets.
   * @returns {Object} { connected, status, lastError }
   */
  function getConnectionStatus() {
    return GoogleDriveService.getConnectionStatus();
  }

  /**
   * Buat spreadsheet gym untuk Owner.
   * @param {Object} body - request body dengan payload { gym_id, owner_user_id }.
   * @returns {Object} { spreadsheetId, spreadsheetUrl }
   */
  function createGymSpreadsheet(body) {
    var payload = body.payload || {};
    var gymId = payload.gym_id;
    var ownerUserId = payload.owner_user_id;

    if (!gymId || !ownerUserId) {
      throw Error('VALIDATION_ERROR', 'gym_id dan owner_user_id wajib diisi');
    }

    var accessToken = Settings.getOAuthAccessToken();
    if (!accessToken) {
      throw Error('GOOGLE_DISCONNECTED', 'Owner belum mengizinkan akses Google Drive');
    }

    var result = GoogleDriveService.createGymSpreadsheet(ownerUserId, gymId, accessToken);

    // Update spreadsheet_id di Gyms tab
    var gym = GymService.findByGymId(gymId);
    if (gym) {
      GymService.update(gymId, { spreadsheet_id: result.spreadsheetId }, ownerUserId);
    }

    return result;
  }

  /**
   * Putuskan koneksi Google Drive/Sheets.
   */
  function disconnect() {
    GoogleDriveService.disconnect();
    return { disconnected: true };
  }

  return {
    startConnect: startConnect,
    handleCallback: handleCallback,
    getConnectionStatus: getConnectionStatus,
    createGymSpreadsheet: createGymSpreadsheet,
    disconnect: disconnect,
  };
})();
