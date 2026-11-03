/**
 * dateTime.gs
 * Helper format tanggal dan waktu. Gunakan ISO 8601 dengan offset eksplisit
 * untuk pertukaran data. Zona waktu tampilan mengikuti pengaturan gym.
 */

var DateTimeHelper = (function () {
  /**
   * Mengembalikan timestamp sekarang dalam format ISO 8601.
   */
  function nowIso() {
    return new Date().toISOString();
  }

  /**
   * Mengembalikan Date sekarang.
   */
  function now() {
    return new Date();
  }

  /**
   * Format tanggal untuk tampilan (DD/MM/YYYY).
   */
  function formatDate(date) {
    var d = new Date(date);
    var day = ('0' + d.getDate()).slice(-2);
    var month = ('0' + (d.getMonth() + 1)).slice(-2);
    return day + '/' + month + '/' + d.getFullYear();
  }

  /**
   * Format waktu untuk tampilan (HH:mm).
   */
  function formatTime(date) {
    var d = new Date(date);
    var hours = ('0' + d.getHours()).slice(-2);
    var minutes = ('0' + d.getMinutes()).slice(-2);
    return hours + ':' + minutes;
  }

  return {
    nowIso: nowIso,
    now: now,
    formatDate: formatDate,
    formatTime: formatTime,
  };
})();
