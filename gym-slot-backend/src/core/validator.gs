/**
 * validator.gs
 * Validasi input untuk mencegah error dan memastikan data konsisten.
 */

var Validator = (function () {
  /**
   * Memeriksa apakah value tidak null/undefined/kosong.
   */
  function required(value, fieldName) {
    if (value === null || value === undefined || value === '') {
      throw Error('VALIDATION_ERROR', fieldName + ' wajib diisi');
    }
  }

  /**
   * Memeriksa apakah value adalah string.
   */
  function isString(value, fieldName) {
    if (typeof value !== 'string') {
      throw Error('VALIDATION_ERROR', fieldName + ' harus berupa string');
    }
  }

  /**
   * Memeriksa apakah value ada dalam list yang diperbolehkan.
   */
  function isIn(value, allowed, fieldName) {
    if (allowed.indexOf(value) === -1) {
      throw Error('VALIDATION_ERROR', fieldName + ' tidak valid');
    }
  }

  /**
   * Memeriksa format email sederhana.
   */
  function isEmail(value, fieldName) {
    if (!value || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
      throw Error('VALIDATION_ERROR', fieldName + ' format email tidak valid');
    }
  }

  return {
    required: required,
    isString: isString,
    isIn: isIn,
    isEmail: isEmail,
  };
})();
