/**
 * uuid.gs
 * Pembangkit UUID versi 4 (acak). Tidak bergantung nomor baris spreadsheet.
 */

var Uuid = (function () {
  /**
   * Menghasilkan UUID v4 string.
   * Menggunakan sumber acak Google Apps Script (Math.random tidak cukup kuat
   * untuk kriptografi; untuk ID data operasional ini memadai sebagai identifier).
   */
  function v4() {
    var chars = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx';
    return chars.replace(/[xy]/g, function (c) {
      var r = (Math.random() * 16) | 0;
      var v = c === 'x' ? r : (r & 0x3) | 0x8;
      return v.toString(16);
    });
  }

  return { v4: v4 };
})();