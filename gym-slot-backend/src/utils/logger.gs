/**
 * logger.gs
 * Audit logging terpusat. Mencatat aksi penting ke Control Sheet (tab AuditLogs).
 * Jangan pernah mencatat refresh token, ID token, atau secret lain ke log.
 */

var Logger = (function () {
  /**
   * Menulis baris audit ke Control Spreadsheet.
   * @param {string} actorUserId - user_id pelaku (bisa kosong jika belum dikenal).
   * @param {string} action - Nama aksi, mis. 'auth.google'.
   * @param {string} resourceType - Jenis sumber, mis. 'user', 'gym'.
   * @param {string} resourceId - ID sumber.
   * @param {string} detail - Detail singkat (tanpa secret).
   */
  function audit(actorUserId, action, resourceType, resourceId, detail) {
    try {
      var sheet = SpreadsheetApp.openById(Settings.getControlSpreadsheetId())
        .getSheetByName('AuditLogs');
      if (!sheet) return;
      sheet.appendRow([
        Uuid.v4(),
        actorUserId || '',
        action,
        resourceType || '',
        resourceId || '',
        detail || '',
        DateTimeHelper.nowIso(),
      ]);
    } catch (e) {
      // Kegagalan audit tidak boleh menggagalkan operasi utama.
      Logger.log('Audit gagal ditulis: ' + action);
    }
  }

  return { audit: audit };
})();