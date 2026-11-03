/**
 * doGet.gs
 * Entry point GET. Untuk PoC dipakai sebagai health check sederhana dan
 * callback OAuth (fase lanjutan). Tidak menerima token lewat URL.
 */

function doGet(e) {
  var params = e && e.parameter ? e.parameter : {};
  var action = params.action || '';

  // OAuth callback dari Google: redirect ke WEB_APP_URL dengan ?code=&state=
  if (params.code && params.state) {
    try {
      GoogleDriveService.handleCallback(params.code);
      return ContentService.createTextOutput(
        'Autorisasi berhasil. Anda dapat kembali ke aplikasi GymSlot.'
      ).setMimeType(ContentService.MimeType.TEXT);
    } catch (err) {
      return ContentService.createTextOutput(
        'Autorisasi gagal: ' + err.message
      ).setMimeType(ContentService.MimeType.TEXT);
    }
  }

  if (action === 'health') {
    return ContentService.createTextOutput(JSON.stringify({
      success: true,
      service: 'gymslot-backend',
      version: Constants.API_VERSION,
    })).setMimeType(ContentService.MimeType.JSON);
  }

  return ContentService.createTextOutput(JSON.stringify({
    success: false,
    error: { code: 'VALIDATION_ERROR', message: 'Method GET hanya untuk health check dan OAuth callback.' },
  })).setMimeType(ContentService.MimeType.JSON);
}