/**
 * backup.gs
 * Backup spreadsheet gym ke folder Drive "GymSlot_Backups" (Phase 7).
 *
 * - createBackup(spreadsheetId, label)  → salinan file GymBooking dengan
 *   nama "GymBooking_backup_<timestamp>_<label>".
 * - backupAllGyms()                     → backup semua gym Active di Control.
 * - listBackups(spreadsheetId)          → daftar backup milik satu gym.
 * - cleanupOldBackups(keepPerGym)       → sisakan N backup terbaru per gym.
 *
 * Backup memakai Drive Advanced Service (Drive.Files.copy) dengan scope
 * drive.file yang sudah ada di appsscript.json. Metadata backup (nama file,
 * waktu, ukuran) dicatat ke AuditLogs.
 *
 * CATATAN PEMULIHAN (restore): salinan dibuat di Drive pemilik script
 * (operator) karena Web App berjalan sebagai USER_DEPLOYING. Untuk restore,
 * buka folder GymSlot_Backups dan bagikan file ke owner gym — data tidak
 * pernah dikirim ke klien.
 */

var BackupService = (function () {
  var BACKUP_FOLDER_NAME = 'GymSlot_Backups';
  var MAX_BACKUPS_PER_GYM = 7;

  function getBackupFolder() {
    var it = DriveApp.getFoldersByName(BACKUP_FOLDER_NAME);
    if (it.hasNext()) return it.next();
    return DriveApp.createFolder(BACKUP_FOLDER_NAME);
  }

  /**
   * Buat salinan backup satu spreadsheet gym.
   * @param {string} spreadsheetId
   * @param {string} label - mis. 'weekly' atau 'pre-migration'.
   * @returns {Object} {backupFileId, name, created_at}
   */
  function createBackup(spreadsheetId, label) {
    if (!spreadsheetId) throw Error('VALIDATION_ERROR', 'spreadsheetId wajib');
    var file = DriveApp.getFileById(spreadsheetId);
    var ts = Utilities.formatDate(new Date(), 'Asia/Jakarta', 'yyyyMMdd-HHmmss');
    var name = file.getName() + '_backup_' + ts + (label ? '_' + label : '');

    var copy = DriveApp.getFileById(spreadsheetId).makeCopy(name, getBackupFolder());

    Logger.audit(null, 'backup.create', 'spreadsheet', spreadsheetId,
      'file=' + copy.getId() + ' name=' + name);

    return {
      backup_file_id: copy.getId(),
      name: name,
      created_at: DateTimeHelper.nowIso(),
    };
  }

  /**
   * Backup semua gym berstatus Active di Control Spreadsheet.
   * Gym tanpa spreadsheet_id dilewati (masih Pending/SetupFailed).
   * @returns {Object} {backed_up: n, skipped: n, results: [...]}
   */
  function backupAllGyms() {
    var rows = ControlRepository.getAllRows('Gyms');
    var backed = 0;
    var skipped = 0;
    var results = [];

    for (var i = 0; i < rows.length; i++) {
      var gym = rows[i];
      var ssId = String(gym.spreadsheet_id || '');
      if (!ssId || String(gym.gym_status) !== 'Active') {
        skipped++;
        results.push({ gym_id: gym.gym_id, status: 'skipped', reason: 'no spreadsheet / not active' });
        continue;
      }
      try {
        var r = createBackup(ssId, 'auto');
        backed++;
        results.push({ gym_id: gym.gym_id, status: 'ok', backup_file_id: r.backup_file_id });
      } catch (e) {
        skipped++;
        results.push({ gym_id: gym.gym_id, status: 'error', reason: e.message });
      }
    }

    return { backed_up: backed, skipped: skipped, results: results };
  }

  /**
   * Daftar file backup untuk satu spreadsheet (berdasarkan nama file).
   */
  function listBackups(spreadsheetId) {
    var folder = getBackupFolder();
    var it = folder.getFiles();
    var out = [];
    var sourceName = DriveApp.getFileById(spreadsheetId).getName();
    while (it.hasNext()) {
      var f = it.next();
      if (f.getName().indexOf(sourceName + '_backup_') === 0) {
        out.push({ id: f.getId(), name: f.getName(), created: f.getDateCreated().toISOString() });
      }
    }
    // Terbaru dulu.
    out.sort(function (a, b) { return b.created.localeCompare(a.created); });
    return out;
  }

  /**
   * Sisakan MAX_BACKUPS_PER_GYM backup terbaru untuk semua gym.
   * @param {number} [keepPerGym] - override jumlah yang disimpan.
   */
  function cleanupOldBackups(keepPerGym) {
    var keep = keepPerGym || MAX_BACKUPS_PER_GYM;
    var rows = ControlRepository.getAllRows('Gyms');
    var deleted = 0;

    for (var i = 0; i < rows.length; i++) {
      var ssId = String(rows[i].spreadsheet_id || '');
      if (!ssId) continue;
      var backups = listBackups(ssId);
      for (var j = keep; j < backups.length; j++) {
        try {
          DriveApp.getFileById(backups[j].id).setTrashed(true);
          deleted++;
        } catch (e) { /* lanjut */ }
      }
    }

    Logger.audit(null, 'backup.cleanup', 'backup', '', 'deleted=' + deleted);
    return { deleted: deleted };
  }

  return {
    createBackup: createBackup,
    backupAllGyms: backupAllGyms,
    listBackups: listBackups,
    cleanupOldBackups: cleanupOldBackups,
    BACKUP_FOLDER_NAME: BACKUP_FOLDER_NAME,
  };
})();

/** Jalankan manual dari editor: backup semua gym. */
function runBackupAllGyms() {
  return BackupService.backupAllGyms();
}
