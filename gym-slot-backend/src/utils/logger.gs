/**
 * logger.gs
 * Logger untuk audit trail dan debugging.
 */

var Logger = (function () {
  /**
   * Mencatat audit log ke tab AuditLogs di Control Spreadsheet.
   * @param {string} actorUserId - ID pengguna yang melakukan aksi.
   * @param {string} action - action yang dilakukan.
   * @param {string} resourceType - tipe resource (gym, user, dll).
   * @param {string} resourceId - ID resource yang dipengaruhi.
   * @param {string} detail - detail tambahan.
   */
  function audit(actorUserId, action, resourceType, resourceId, detail) {
    try {
      ControlRepository.insertRow('AuditLogs', {
        log_id: Uuid.v4(),
        actor_user_id: actorUserId || '',
        action: action || '',
        resource_type: resourceType || '',
        resource_id: resourceId || '',
        detail: detail || '',
        created_at: DateTimeHelper.nowIso(),
      });
    } catch (e) {
      // Jangan biarkan error logging mengganggu aliran utama.
      Logger.log('Audit log failed: ' + e.message);
    }
  }

  function log(message) {
    console.log('[GymSlot] ' + message);
  }

  function error(message) {
    console.error('[GymSlot] ERROR: ' + message);
  }

  return {
    audit: audit,
    log: log,
    error: error,
  };
})();
