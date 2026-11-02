/**
 * controlRepository.gs
 * Repository untuk membaca/menulis Control Spreadsheet (GymSlot_Control).
 * Control Spreadsheet TIDAK boleh dibagikan ke pengguna gym.
 */

var ControlRepository = (function () {
  /** Ambil spreadsheet Control; lempar error jika belum dikonfigurasi. */
  function getSpreadsheet() {
    var id = Settings.getControlSpreadsheetId();
    if (!id) {
      throw Error('CONTROL_SPREADSHEET_NOT_CONFIGURED');
    }
    return SpreadsheetApp.openById(id);
  }

  function getSheet(tab) {
    var sheet = getSpreadsheet().getSheetByName(tab);
    if (!sheet) {
      throw Error('CONTROL_TAB_NOT_FOUND:' + tab);
    }
    return sheet;
  }

  /**
   * Membaca semua baris tab sebagai array of objects dengan key = header.
   * Baris header di baris 1.
   */
  function getAllRows(tab) {
    var sheet = getSheet(tab);
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
   * Membaca baris yang memenuhi matcher. Mengembalikan baris pertama yang cocok.
   * @param {string} tab
   * @param {Object} matcher - pasangan {kolom: nilai}.
   */
  function findOne(tab, matcher) {
    var rows = getAllRows(tab);
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
   * Menyisipkan satu baris ke akhir tab.
   * @param {string} tab
   * @param {Object} valuesByHeader - {nama_kolom: nilai}.
   */
  function insertRow(tab, valuesByHeader) {
    var sheet = getSheet(tab);
    var headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
    var row = [];
    for (var h = 0; h < headers.length; h++) {
      row.push(valuesByHeader[headers[h]] !== undefined ? valuesByHeader[headers[h]] : '');
    }
    sheet.appendRow(row);
    return valuesByHeader;
  }

  return {
    getSpreadsheet: getSpreadsheet,
    getSheet: getSheet,
    getAllRows: getAllRows,
    findOne: findOne,
    insertRow: insertRow,
  };
})();