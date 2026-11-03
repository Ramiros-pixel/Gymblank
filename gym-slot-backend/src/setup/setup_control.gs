/**
 * setup_control.gs
 * Setup Control Spreadsheet: membuat tab dan header jika belum ada.
 * Idempotent: tidak membuat duplikat.
 */

var ControlSetup = (function () {
  /**
   * Memastikan Control Spreadsheet exist dengan semua tab yang diperlukan.
   * Dipanggil sekali oleh admin platform.
   */
  function setup() {
    var ss = getOrCreateControlSpreadsheet();
    for (var i = 0; i < Constants.CONTROL_TABS.length; i++) {
      var tab = Constants.CONTROL_TABS[i];
      ensureTab(ss, tab, Constants.CONTROL_HEADERS[tab]);
    }
    return { success: true, message: 'Control Spreadsheet siap' };
  }

  function getOrCreateControlSpreadsheet() {
    var sheets = SpreadsheetApp.getSheets();
    for (var i = 0; i < sheets.length; i++) {
      if (sheets[i].getSheetName() === Constants.CONTROL_SPREADSHEET_NAME) {
        return SpreadsheetApp.openById(sheets[i].getSpreadsheetId());
      }
    }
    // Buat baru
    var ss = SpreadsheetApp.create(Constants.CONTROL_SPREADSHEET_NAME);
    return ss;
  }

  function ensureTab(ss, tabName, headers) {
    var sheet = ss.getSheetByName(tabName);
    if (sheet) return; // sudah ada

    sheet = ss.insertSheet(tabName);
    sheet.appendRow(headers);
    // Format header: bold, background hijau
    var headerRange = sheet.getRange(1, 1, 1, headers.length);
    headerRange.setFontWeight('bold');
    headerRange.setBackground('#2E7D32');
    headerRange.setFontColor('#FFFFFF');
  }

  return { setup: setup };
})();

/**
 * Fungsi trigger untuk setup manual.
 */
function setupControlSpreadsheet() {
  var result = ControlSetup.setup();
  Logger.log(JSON.stringify(result));
  return result;
}
