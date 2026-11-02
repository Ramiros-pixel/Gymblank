/**
 * setup_control.gs
 * Script setup Control Spreadsheet (GymSlot_Control).
 * Membuat spreadsheet (jika belum ada), membuat tab dan header.
 *
 * JALANKAN SETELAH: mengatur Settings.setControlSpreadsheetId().
 * Menjalankan fungsi setupControl() dari editor Apps Script.
 *
 * Idempotent: jika tab sudah ada dan header terisi, tidak membuat duplikat.
 */

/**
 * Membuat/menormalisasi Control Spreadsheet.
 * @returns {Object} {spreadsheet_id, created}
 */
function setupControl() {
  var id = Settings.getControlSpreadsheetId();
  var created = false;

  var ss;
  if (!id) {
    // PoC: buat spreadsheet di Drive akun deployer (bukan akun Owner gym).
    // Untuk produksi, spreadsheet per gym dibuat di Drive Owner (Phase 2).
    ss = SpreadsheetApp.create(Constants.CONTROL_SPREADSHEET_NAME);
    Settings.setControlSpreadsheetId(ss.getId());
    created = true;
  } else {
    try {
      ss = SpreadsheetApp.openById(id);
    } catch (e) {
      throw Error('SHEET_NOT_FOUND: control spreadsheet tidak ditemukan');
    }
  }

  // Buat/normalisasi tab dan header.
  for (var i = 0; i < Constants.CONTROL_TABS.length; i++) {
    ensureTab(ss, Constants.CONTROL_TABS[i], Constants.CONTROL_HEADERS[Constants.CONTROL_TABS[i]]);
  }

  return {
    spreadsheet_id: ss.getId(),
    created: created,
  };
}

/** Memastikan tab ada dan baris header sesuai. Idempotent. */
function ensureTab(ss, tabName, headers) {
  var sheet = ss.getSheetByName(tabName);
  if (!sheet) {
    sheet = ss.insertSheet(tabName);
  }
  var existingHeaders = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  var needsHeaders = existingHeaders.length === 1 && !existingHeaders[0];
  if (needsHeaders) {
    sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
  }
}