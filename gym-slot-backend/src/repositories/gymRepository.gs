/**
 * gymRepository.gs
 * Repository untuk tab operasional di spreadsheet GymBooking milik gym.
 * Berbeda dengan ControlRepository yang membaca Control Spreadsheet platform,
 * repository ini bekerja pada spreadsheet per-gym (tenant isolation via
 * TenantResolver.resolveSpreadsheetId).
 *
 * Sesuai TECHNICAL_DOCUMENTATION 4.5-4.9 dan 17:
 * tab Members, Facilities, Schedules, Bookings, Attendance, Settings,
 * AuditLogs ada di spreadsheet gym, bukan di Control Spreadsheet.
 */

var GymRepository = (function () {
  /**
   * Ambil objek Spreadsheet gym.
   * @param {string} spreadsheetId - ID spreadsheet gym (dari metadata backend).
   */
  function getSpreadsheet(spreadsheetId) {
    if (!spreadsheetId) {
      throw Error('GOOGLE_DISCONNECTED');
    }
    try {
      return SpreadsheetApp.openById(spreadsheetId);
    } catch (e) {
      throw Error('SHEET_NOT_FOUND');
    }
  }

  function getSheet(spreadsheetId, tab) {
    var sheet = getSpreadsheet(spreadsheetId).getSheetByName(tab);
    if (!sheet) {
      throw Error('SHEET_NOT_FOUND:' + tab);
    }
    return sheet;
  }

  /**
   * Membaca semua baris tab gym sebagai array of objects (key = header).
   * @param {string} spreadsheetId
   * @param {string} tab
   */
  function getAllRows(spreadsheetId, tab) {
    var sheet = getSheet(spreadsheetId, tab);
    var values = sheet.getDataRange().getValues();
    if (values.length === 0) return [];
    var headers = values[0];
    var rows = [];
    for (var i = 1; i < values.length; i++) {
      var obj = {};
      for (var h = 0; h < headers.length; h++) {
        obj[headers[h]] = values[i][h];
      }
      rows.push(obj);
    }
    return rows;
  }

  /**
   * Cari baris pertama yang cocok dengan matcher.
   */
  function findOne(spreadsheetId, tab, matcher) {
    var rows = getAllRows(spreadsheetId, tab);
    for (var i = 0; i < rows.length; i++) {
      var match = true;
      for (var key in matcher) {
        if (String(rows[i][key]) !== String(matcher[key])) {
          match = false;
          break;
        }
      }
      if (match) return rows[i];
    }
    return null;
  }

  /**
   * Sisipkan satu baris ke akhir tab gym.
   * @param {string} spreadsheetId
   * @param {string} tab
   * @param {Object} valuesByHeader - {nama_kolom: nilai}
   */
  function insertRow(spreadsheetId, tab, valuesByHeader) {
    var sheet = getSheet(spreadsheetId, tab);
    var headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
    var row = [];
    for (var h = 0; h < headers.length; h++) {
      row.push(valuesByHeader[headers[h]] !== undefined ? valuesByHeader[headers[h]] : '');
    }
    sheet.appendRow(row);
    return valuesByHeader;
  }

  /**
   * Perbarui satu baris berdasarkan kolom ID.
   * @param {string} spreadsheetId
   * @param {string} tab
   * @param {string} idColumn - nama kolom ID (mis. 'member_id')
   * @param {string} idValue - nilai ID
   * @param {Object} updates - {nama_kolom: nilai_baru}
   * @returns {Object|null} baris setelah update, atau null jika ID tidak ketemu.
   */
  function updateRow(spreadsheetId, tab, idColumn, idValue, updates) {
    var sheet = getSheet(spreadsheetId, tab);
    var data = sheet.getDataRange().getValues();
    if (data.length === 0) return null;
    var headers = data[0];
    var idIdx = headers.indexOf(idColumn);
    if (idIdx < 0) return null;

    for (var i = 1; i < data.length; i++) {
      if (String(data[i][idIdx]) === String(idValue)) {
        for (var key in updates) {
          var colIdx = headers.indexOf(key);
          if (colIdx >= 0) {
            sheet.getRange(i + 1, colIdx + 1).setValue(updates[key]);
          }
        }
        // updated_at otomatis jika kolom ada
        var updatedAtIdx = headers.indexOf('updated_at');
        if (updatedAtIdx >= 0 && !updates.updated_at) {
          sheet.getRange(i + 1, updatedAtIdx + 1).setValue(DateTimeHelper.nowIso());
        }
        // Kembalikan baris terbaru
        var updated = sheet.getRange(i + 1, 1, 1, headers.length).getValues()[0];
        var obj = {};
        for (var h = 0; h < headers.length; h++) {
          obj[headers[h]] = updated[h];
        }
        return obj;
      }
    }
    return null;
  }

  /**
   * Tulis audit log ke tab AuditLogs spreadsheet gym.
   */
  function audit(spreadsheetId, actorUserId, action, resourceType, resourceId, detail) {
    try {
      insertRow(spreadsheetId, 'AuditLogs', {
        log_id: Uuid.v4(),
        actor_user_id: actorUserId || '',
        action: action,
        resource_type: resourceType,
        resource_id: resourceId,
        detail: detail || '',
        created_at: DateTimeHelper.nowIso(),
      });
    } catch (e) {
      // Audit log tidak boleh memblokir operasi utama.
    }
  }

  return {
    getSpreadsheet: getSpreadsheet,
    getSheet: getSheet,
    getAllRows: getAllRows,
    findOne: findOne,
    insertRow: insertRow,
    updateRow: updateRow,
    audit: audit,
  };
})();
