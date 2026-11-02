/**
 * validator.gs
 * Validasi input terpusat. Validasi dasar di sini, validasi final tetap di backend.
 * Flutter hanya melakukan validasi awal; backend tidak mempercayai input klien.
 */

var Validator = (function () {
  function isNonEmptyString(value) {
    return typeof value === 'string' && value.trim().length > 0;
  }

  function isObject(value) {
    return value !== null && typeof value === 'object' && !Array.isArray(value);
  }

  function isIsoDateString(value) {
    if (typeof value !== 'string') return false;
    return !isNaN(Date.parse(value));
  }

  function isUuid(value) {
    return typeof value === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
  }

  function isEmail(value) {
    return typeof value === 'string' &&
      /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
  }

  /**
   * Membangun daftar error validasi.
   * @param {Array.<{field:string, message:string}>} checks - hasil false berarti gagal.
   * Dipanggil manual per field.
   */
  function summarize(errors) {
    if (errors.length === 0) return null;
    return { fields: errors };
  }

  return {
    isNonEmptyString: isNonEmptyString,
    isObject: isObject,
    isIsoDateString: isIsoDateString,
    isUuid: isUuid,
    isEmail: isEmail,
    summarize: summarize,
  };
})();